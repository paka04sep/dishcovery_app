const { onObjectFinalized } = require("firebase-functions/v2/storage");
const admin = require("firebase-admin");
const { getDownloadURL } = require("firebase-admin/storage");

admin.initializeApp();

exports.onRestaurantImageUpload = onObjectFinalized(
  { region: "us-central1" },
  async (event) => {
    const object = event.data;
    if (!object || !object.name) return;

    console.log("File uploaded:", object.name);

    // path: res_0001/main/hero.jpg
    const parts = object.name.split("/");
    if (parts.length < 3) return;

    const restaurantId = parts[0];
    const folder = parts[1]; // main | gallery | menu

    const bucket = admin.storage().bucket(object.bucket);
    const file = bucket.file(object.name);
 
    const downloadURL = await getDownloadURL(file);
    console.log("Download URL:", downloadURL);

    const ref = admin.firestore()
      .collection("restaurants")
      .doc(restaurantId);

    if (folder === "main") {
      await ref.update({
        imageUrl: downloadURL,
      });
    }

    if (folder === "gallery") {
      await ref.update({
        galleryImages: admin.firestore.FieldValue.arrayUnion(downloadURL),
      });
    }

    console.log("Firestore updated");
  }
);