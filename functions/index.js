const admin = require("firebase-admin");
admin.initializeApp();
const { onCall } = require("firebase-functions/v2/https");

// Helper to calculate score based on action & dwell time
function calculateSwipeScore(action, dwellTimeSec) {
  let score = 0;
  if (action === "pass") score = -1;
  else if (action === "yum") score = 2;
  else if (action === "fav") score = 3;

  if (dwellTimeSec >= 3 && score > 0) {
    score += 1;
  }
  return score;
}

// 1. Record Swipe Action
exports.recordSwipeAction = onCall({ region: "us-central1" }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new Error("Unauthorized");

  const { restaurantId, action, dwellTime = 0 } = request.data;
  if (!restaurantId || !action) throw new Error("Missing parameters");

  const db = admin.firestore();
  const baseScore = calculateSwipeScore(action, dwellTime);

  // Run in a transaction
  const userRef = db.collection("users").doc(uid);
  const restaurantRef = db.collection("restaurants").doc(restaurantId);

  await db.runTransaction(async (t) => {
    const userDoc = await t.get(userRef);
    const resDoc = await t.get(restaurantRef);

    if (!userDoc.exists || !resDoc.exists) return;

    const resData = resDoc.data();
    
    // --- 1. Update User Taste Profile & History ---
    const userData = userDoc.data();
    const tasteProfile = userData.tasteProfile || { categories: {}, priceRange: {}, timeAffinity: {} };
    if (!tasteProfile.categories) tasteProfile.categories = {};
    if (!tasteProfile.priceRange) tasteProfile.priceRange = {};
    if (!tasteProfile.timeAffinity) tasteProfile.timeAffinity = {};
    
    const cuisines = resData.cuisine || [];
    cuisines.forEach(c => {
      tasteProfile.categories[c] = (tasteProfile.categories[c] || 0) + baseScore;
    });

    const priceStr = resData.priceRange?.toString() || "1";
    tasteProfile.priceRange[priceStr] = (tasteProfile.priceRange[priceStr] || 0) + baseScore;

    const hour = new Date().getHours();
    let timeKey = "other";
    if (hour >= 5 && hour < 11) timeKey = "morning";
    else if (hour >= 11 && hour < 14) timeKey = "lunch";
    else if (hour >= 14 && hour < 17) timeKey = "afternoon";
    else if (hour >= 17 && hour < 22) timeKey = "dinner";
    else timeKey = "late_night";
    
    tasteProfile.timeAffinity[timeKey] = (tasteProfile.timeAffinity[timeKey] || 0) + baseScore;

    // Preserve history arrays and general stats
    const history = userData.history || { yum: [], passed: [], fav: [] };
    const stats = userData.stats || { yums: 0, passes: 0, totalSwipes: 0 };

    if (!history.yum) history.yum = [];
    if (!history.passed) history.passed = [];
    if (!history.fav) history.fav = [];

    // Remove from existing lists to prevent duplicates
    history.yum = history.yum.filter(id => id !== restaurantId);
    history.passed = history.passed.filter(id => id !== restaurantId);
    history.fav = history.fav.filter(id => id !== restaurantId);

    // Add to appropriate array and increment general stats
    stats.totalSwipes += 1;
    if (action === 'yum') {
      history.yum.unshift(restaurantId);
      stats.yums += 1;
    } else if (action === 'pass') {
      history.passed.unshift(restaurantId);
      stats.passes += 1;
    } else if (action === 'fav') {
      history.fav.unshift(restaurantId);
      stats.yums += 1; // Assuming fav counts as yum for general stats?
    }

    t.update(userRef, { 
      tasteProfile,
      history,
      stats
    });

    // Subcollection logging for Dashboard & Analytics
    const swipeRef = userRef.collection("swipes").doc();
    t.set(swipeRef, {
      restaurantId: restaurantId,
      action: action,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    // --- 2. Update Restaurant Engagement & Trending ---
    let engagement = resData.engagementStats || {
      totalViews: 0, totalYums: 0, totalPasses: 0, totalFavs: 0, totalDwellTime: 0,
      trendingScore: 0.0, lastTrendingUpdate: Date.now()
    };

    engagement.totalViews += 1;
    engagement.totalDwellTime += dwellTime;
    if (action === "yum") engagement.totalYums += 1;
    else if (action === "pass") engagement.totalPasses += 1;
    else if (action === "fav") engagement.totalFavs += 1;

    // Time-decay for trending (half-life of 3 days)
    const now = Date.now();
    const lastUpdate = engagement.lastTrendingUpdate || now;
    const daysPassed = (now - lastUpdate) / (1000 * 60 * 60 * 24);
    let currentTrending = engagement.trendingScore || 0;
    
    if (daysPassed > 0) {
      currentTrending = currentTrending * Math.pow(0.5, daysPassed / 3);
    }
    
    if (action === "yum") currentTrending += 2;
    if (action === "fav") currentTrending += 3;
    if (dwellTime > 3) currentTrending += 0.5;

    engagement.trendingScore = currentTrending;
    engagement.lastTrendingUpdate = now;

    t.update(restaurantRef, { engagementStats: engagement });
  });

  return { success: true };
});

// ===== Cuisine Keyword Map (mirrors Dart CuisineUtils) =====
const cuisineKeywordMap = {
  'อาหารไทย': ['อาหารไทย', 'ข้าว', 'กับข้าว', 'อาหารตามสั่ง'],
  'อาหารอีสาน': ['อีสาน', 'ส้มตำ', 'ลาบ', 'น้ำตก', 'ไก่ย่าง', 'อาหารอีสาน'],
  'อาหารเหนือ': ['เหนือ', 'ขันโตก', 'ข้าวซอย', 'น้ำพริก', 'อาหารเหนือ', 'ส้มตำ ไก่ย่าง'],
  'อาหารใต้': ['ใต้', 'แกงใต้', 'คั่วกลิ้ง', 'ข้าวยำ', 'อาหารใต้'],
  'อาหารญี่ปุ่น': ['ญี่ปุ่น', 'ซูชิ', 'ซาชิมิ', 'ราเมน', 'อิซากายะ', 'ดงบุริ', 'อาหารญี่ปุ่น'],
  'อาหารเกาหลี': ['เกาหลี', 'ปิ้งย่างเกาหลี', 'คิมบับ', 'ต๊อกบกกี', 'อาหารเกาหลี'],
  'อาหารจีน': ['จีน', 'ติ่มซำ', 'หม่าล่า', 'หม้อไฟ', 'บะหมี่', 'อาหารจีน'],
  'อาหารตะวันตก': ['อาหารตะวันตก', 'สเต็ก', 'พาสต้า', 'อิตาเลียน', 'ฝรั่ง'],
  'ฟาสต์ฟู้ด': ['ฟาสต์ฟู้ด', 'อาหารจานด่วน'],
  'เบอร์เกอร์': ['เบอร์เกอร์', 'อาหารตะวันตก', 'ฟาสต์ฟู้ด'],
  'พิซซ่า': ['พิซซ่า', 'อาหารตะวันตก', 'ฟาสต์ฟู้ด'],
  'ไก่ทอด': ['ไก่ทอด', 'ไก่กรอบ'],
  'ก๋วยเตี๋ยว': ['ก๋วยเตี๋ยว', 'เส้น', 'บะหมี่'],
  'ข้าวแกง': ['ข้าวแกง', 'กับข้าว'],
  'ข้าวมันไก่': ['ข้าวมันไก่'],
  'อาหารตามสั่ง': ['ตามสั่ง', 'ผัด', 'ทอด'],
  'ส้มตำ ไก่ย่าง': ['ส้มตำ', 'ไก่ย่าง', 'อีสาน'],
  'ปิ้งย่าง': ['ปิ้งย่าง', 'ย่าง', 'bbq'],
  'ชาบู / สุกี้': ['ชาบู', 'สุกี้', 'หม้อไฟ'],
  'เบเกอรี่': ['เบเกอรี่', 'ขนมปัง'],
  'ของหวาน': ['ของหวาน', 'ขนม'],
  'ไอศกรีม': ['ไอศกรีม'],
  'เครป': ['เครป'],
  'กาแฟ': ['กาแฟ', 'คาเฟ่'],
  'ชา / ชานม': ['ชา', 'ชานม'],
  'เครื่องดื่ม': ['เครื่องดื่ม', 'น้ำ'],
  'อาหารเพื่อสุขภาพ': ['สุขภาพ', 'เฮลตี้', 'low fat'],
  'มังสวิรัติ': ['มังสวิรัติ', 'เจ', 'vegan'],
  'คลีน': ['คลีน', 'clean food'],
};

function expandPreferencesToKeywords(preferences) {
  const keywords = new Set();
  (preferences || []).forEach(pref => {
    const mapped = cuisineKeywordMap[pref.trim()];
    if (mapped) {
      mapped.forEach(k => keywords.add(k));
    } else {
      keywords.add(pref.trim());
    }
  });
  return keywords;
}

// Helper: Map price range display strings to numeric values
function parsePriceRangeStrings(priceRangeStrings) {
  const numericSet = new Set();
  (priceRangeStrings || []).forEach(s => {
    if (s.includes('ถูกกว่า 100') || s.startsWith('฿ ')) numericSet.add(1);
    else if (s.includes('100-250') || s.startsWith('฿฿ ')) numericSet.add(2);
    else if (s.includes('251-500') || s.startsWith('฿฿฿ ') && !s.startsWith('฿฿฿฿')) numericSet.add(3);
    else if (s.includes('500+') || s.startsWith('฿฿฿฿')) numericSet.add(4);
  });
  return numericSet;
}

// 2. The Batch Engine (Get Recommendations)
exports.getRecommendedBatch = onCall({ region: "us-central1" }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new Error("Unauthorized");

  const { 
    latitude = 0, 
    longitude = 0, 
    excludeIds = [], 
    preferences: clientPreferences = null,
    maxDistance = 50,
    priceRangePreference = [],
    showClosedRestaurants = true,
  } = request.data;
  const db = admin.firestore();

  const userDoc = await db.collection("users").doc(uid).get();
  const userData = userDoc.data() || {};
  const tasteProfile = userData.tasteProfile || { categories: {}, priceRange: {} };
  
  // Read explicit preferences: prefer client-sent (latest) over Firestore
  const userPreferences = clientPreferences || userData.preferences || [];
  const prefKeywords = expandPreferencesToKeywords(userPreferences);

  // Parse price range preference into numeric set for filtering
  const allowedPriceRanges = parsePriceRangeStrings(
    priceRangePreference.length > 0 ? priceRangePreference : (userData.priceRangePreference || [])
  );
  const effectiveMaxDistance = maxDistance || userData.distancePreference || 50;

  const categoryScores = tasteProfile.categories || {};
  let topUserCategories = Object.keys(categoryScores).filter(k => categoryScores[k] > 0);

  const snapshot = await db.collection("restaurants").where("status", "==", "approved").limit(30).get();
  
  let candidates = [];
  snapshot.forEach(doc => {
    // Only exclude IDs from this session / locally so we don't repeat in the same run
    if (!excludeIds.includes(doc.id)) {
      candidates.push({ id: doc.id, ...doc.data() });
    }
  });

  function getDistance(lat1, lon1, lat2, lon2) {
    if (!lat1 || !lon1 || !lat2 || !lon2) return 999;
    const p = 0.017453292519943295;
    const c = Math.cos;
    const a = 0.5 - c((lat2 - lat1) * p)/2 + 
            c(lat1 * p) * c(lat2 * p) * 
            (1 - c((lon2 - lon1) * p))/2;
    return 12742 * Math.asin(Math.sqrt(a));
  }

  // === Compute distance for ALL candidates first ===
  if (latitude !== 0 && longitude !== 0) {
    candidates = candidates.map(r => {
      r._dist = getDistance(latitude, longitude, r.latitude, r.longitude);
      return r;
    });
  }

  // === Smart Filter: Distance (with fallback) ===
  let distFiltered = candidates.filter(r => (r._dist || 0) <= effectiveMaxDistance);
  if (distFiltered.length === 0) {
    // Fallback: no restaurants within range, sort by nearest and take top 20
    console.log(`No restaurants within ${effectiveMaxDistance}km, falling back to nearest available`);
    distFiltered = [...candidates].sort((a, b) => (a._dist || 999) - (b._dist || 999)).slice(0, 20);
  }
  candidates = distFiltered;

  // NOTE: Price Range is now a SOFT BOOST, not a hard filter.
  // This ensures cuisine-matched restaurants always appear even if their
  // price doesn't exactly match the user's preference.
  // Priority: Cuisine Preference (+15) > Price Range Match (+5) > Distance (penalty)

  const PREFERENCE_BOOST = 15; // High boost for explicit cuisine preference match
  const PRICE_MATCH_BOOST = 5; // Moderate boost for matching price range

  candidates = candidates.map(r => {
    let score = 0;
    const rCuisines = r.cuisine || [];

    // === Explicit Preference Boost (HIGHEST PRIORITY) ===
    // If any restaurant cuisine matches keywords from user preferences, boost significantly
    let prefMatched = false;
    if (prefKeywords.size > 0) {
      for (const c of rCuisines) {
        if (prefKeywords.has(c)) {
          prefMatched = true;
          break;
        }
        // Also check partial match (e.g. cuisine "อาหารญี่ปุ่น" contains keyword "ญี่ปุ่น")
        for (const kw of prefKeywords) {
          if (c.includes(kw) || kw.includes(c)) {
            prefMatched = true;
            break;
          }
        }
        if (prefMatched) break;
      }
    }
    if (prefMatched) {
      score += PREFERENCE_BOOST;
    }

    // === Price Range Match (SOFT BOOST, not a filter) ===
    if (allowedPriceRanges.size > 0) {
      const rPrice = r.priceRange || 1;
      if (allowedPriceRanges.has(rPrice)) {
        score += PRICE_MATCH_BOOST; // Bonus for matching price range
      }
      // No penalty for non-matching — just no bonus
    }

    // === Taste Profile (implicit history) ===
    rCuisines.forEach(c => {
      if (categoryScores[c]) score += categoryScores[c];
    });
    const pStr = r.priceRange?.toString() || "1";
    if (tasteProfile.priceRange && tasteProfile.priceRange[pStr]) {
      score += tasteProfile.priceRange[pStr];
    }
    
    // Distance penalty
    let dist = r._dist || 999;
    if (latitude !== 0 && longitude !== 0 && !r._dist) {
      dist = getDistance(latitude, longitude, r.latitude, r.longitude);
    }
    score -= dist * 0.1;

    const trend = r.engagementStats?.trendingScore || 0;
    return { ...r, _personalScore: score, _dist: dist, _trend: trend, _prefMatch: prefMatched };
  });

  // 1. Personalized (7)
  let personalizedCandidates = [...candidates].sort((a, b) => b._personalScore - a._personalScore);
  const personalized = personalizedCandidates.slice(0, 7);
  const pickedIds = new Set(personalized.map(p => p.id));

  // 2. Discovery (2)
  let discoveryCandidates = candidates.filter(r => {
    if (pickedIds.has(r.id)) return false;
    const rCuisines = r.cuisine || [];
    return !rCuisines.some(c => topUserCategories.includes(c));
  });
  discoveryCandidates.sort(() => 0.5 - Math.random());
  
  let discovery = discoveryCandidates.slice(0, 2);
  discovery.forEach(d => pickedIds.add(d.id));
  
  if (discovery.length < 2) {
    const fallback = candidates.filter(c => !pickedIds.has(c.id)).sort(() => 0.5 - Math.random());
    const needed = 2 - discovery.length;
    discovery.push(...fallback.slice(0, needed));
    fallback.slice(0, needed).forEach(d => pickedIds.add(d.id));
  }

  // 3. Trending (1)
  let trendingCandidates = candidates.filter(r => !pickedIds.has(r.id));
  trendingCandidates.sort((a, b) => b._trend - a._trend);
  const trending = trendingCandidates.slice(0, 1);
  trending.forEach(t => pickedIds.add(t.id));

  let finalBatch = [...personalized, ...discovery, ...trending];

  // Sort final batch: preference-matched restaurants first, then by personalScore desc
  finalBatch.sort((a, b) => {
    // Preference matches first
    if (a._prefMatch && !b._prefMatch) return -1;
    if (!a._prefMatch && b._prefMatch) return 1;
    // Then by personalScore
    return b._personalScore - a._personalScore;
  });
  
  finalBatch = finalBatch.map(r => {
    delete r._personalScore;
    delete r._dist;
    delete r._trend;
    delete r._prefMatch;
    return r;
  });

  return { restaurants: finalBatch };
});

// 3. Batch Swipe Actions — Process multiple swipes in a single call
exports.recordSwipeActionsBatch = onCall({ region: "us-central1" }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new Error("Unauthorized");

  const { actions = [] } = request.data;
  if (!Array.isArray(actions) || actions.length === 0) {
    return { success: true, processed: 0 };
  }

  // Safety cap: max 20 actions per batch
  const batch = actions.slice(0, 20);
  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (t) => {
    const userDoc = await t.get(userRef);
    if (!userDoc.exists) return;

    const userData = userDoc.data();
    const tasteProfile = userData.tasteProfile || { categories: {}, priceRange: {}, timeAffinity: {} };
    if (!tasteProfile.categories) tasteProfile.categories = {};
    if (!tasteProfile.priceRange) tasteProfile.priceRange = {};
    if (!tasteProfile.timeAffinity) tasteProfile.timeAffinity = {};

    const history = userData.history || { yum: [], passed: [], fav: [] };
    if (!history.yum) history.yum = [];
    if (!history.passed) history.passed = [];
    if (!history.fav) history.fav = [];

    const stats = userData.stats || { yums: 0, passes: 0, totalSwipes: 0 };

    // Pre-fetch all restaurant docs needed
    const restaurantRefs = batch.map(a => db.collection("restaurants").doc(a.restaurantId));
    const restaurantDocs = await Promise.all(restaurantRefs.map(ref => t.get(ref)));
    const restaurantMap = {};
    restaurantDocs.forEach((doc, i) => {
      if (doc.exists) restaurantMap[batch[i].restaurantId] = { ref: restaurantRefs[i], data: doc.data() };
    });

    // Process each action
    for (const item of batch) {
      const { restaurantId, action, dwellTime = 0 } = item;
      if (!restaurantId || !action) continue;

      const resEntry = restaurantMap[restaurantId];
      if (!resEntry) continue;

      const resData = resEntry.data;
      const baseScore = calculateSwipeScore(action, dwellTime);

      // Update taste profile
      const cuisines = resData.cuisine || [];
      cuisines.forEach(c => {
        tasteProfile.categories[c] = (tasteProfile.categories[c] || 0) + baseScore;
      });

      const priceStr = resData.priceRange?.toString() || "1";
      tasteProfile.priceRange[priceStr] = (tasteProfile.priceRange[priceStr] || 0) + baseScore;

      const hour = new Date().getHours();
      let timeKey = "other";
      if (hour >= 5 && hour < 11) timeKey = "morning";
      else if (hour >= 11 && hour < 14) timeKey = "lunch";
      else if (hour >= 14 && hour < 17) timeKey = "afternoon";
      else if (hour >= 17 && hour < 22) timeKey = "dinner";
      else timeKey = "late_night";
      tasteProfile.timeAffinity[timeKey] = (tasteProfile.timeAffinity[timeKey] || 0) + baseScore;

      // Update history arrays
      history.yum = history.yum.filter(id => id !== restaurantId);
      history.passed = history.passed.filter(id => id !== restaurantId);
      history.fav = history.fav.filter(id => id !== restaurantId);

      stats.totalSwipes += 1;
      if (action === 'yum') {
        history.yum.unshift(restaurantId);
        stats.yums += 1;
      } else if (action === 'pass') {
        history.passed.unshift(restaurantId);
        stats.passes += 1;
      } else if (action === 'fav') {
        history.fav.unshift(restaurantId);
        stats.yums += 1;
      }

      // Log to subcollection
      const swipeRef = userRef.collection("swipes").doc();
      t.set(swipeRef, {
        restaurantId,
        action,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });

      // Update restaurant engagement
      let engagement = resData.engagementStats || {
        totalViews: 0, totalYums: 0, totalPasses: 0, totalFavs: 0, totalDwellTime: 0,
        trendingScore: 0.0, lastTrendingUpdate: Date.now()
      };

      engagement.totalViews += 1;
      engagement.totalDwellTime += dwellTime;
      if (action === "yum") engagement.totalYums += 1;
      else if (action === "pass") engagement.totalPasses += 1;
      else if (action === "fav") engagement.totalFavs += 1;

      const now = Date.now();
      const lastUpdate = engagement.lastTrendingUpdate || now;
      const daysPassed = (now - lastUpdate) / (1000 * 60 * 60 * 24);
      let currentTrending = engagement.trendingScore || 0;
      if (daysPassed > 0) {
        currentTrending = currentTrending * Math.pow(0.5, daysPassed / 3);
      }
      if (action === "yum") currentTrending += 2;
      if (action === "fav") currentTrending += 3;
      if (dwellTime > 3) currentTrending += 0.5;
      engagement.trendingScore = currentTrending;
      engagement.lastTrendingUpdate = now;

      t.update(resEntry.ref, { engagementStats: engagement });
    }

    // Commit user updates once
    t.update(userRef, {
      tasteProfile,
      history,
      stats
    });
  });

  return { success: true, processed: batch.length };
});
