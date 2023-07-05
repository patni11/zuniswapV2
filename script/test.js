const ethers = require("ethers");
const CryptoJS = require("crypto-js");

// Recipients' Ethereum private keys (NEVER share these with anyone)
const privateKey1 =
  "0x0123456789012345678901234567890123456789012345678901234567890123";
const privateKey2 =
  "0x9876543210987654321098765432109876543210987654321098765432109876";

// Derive public keys from private keys
const wallet1 = new ethers.Wallet(privateKey1);
const wallet2 = new ethers.Wallet(privateKey2);
const publicKey1 = wallet1.publicKey;
const publicKey2 = wallet2.publicKey;

// Generate a random symmetric key (hex encoded)
const symmetricKey = CryptoJS.lib.WordArray.random(256 / 8).toString(
  CryptoJS.enc.Hex
);

// Encrypt the message using AES and the symmetric key
const message = "Hello, world! This is Shubh";
const encryptedMessage = CryptoJS.AES.encrypt(message, symmetricKey).toString();
console.log(encryptedMessage);

// // Encrypt the symmetric key using recipients' public keys (ECIES)
// const encryptedKey1 = ethers.utils.encrypt(
//   publicKey1,
//   ethers.utils.toUtf8Bytes(symmetricKey)
// );
// const encryptedKey2 = ethers.utils.encrypt(
//   publicKey2,
//   ethers.utils.toUtf8Bytes(symmetricKey)
// );

// // Each recipient can now decrypt the symmetric key using their private key, and then decrypt the message using the symmetric key
// const decryptedSymmetricKey1 = ethers.utils.toUtf8String(
//   ethers.utils.decrypt(privateKey1, encryptedKey1)
// );
// const decryptedMessage1 = CryptoJS.AES.decrypt(
//   encryptedMessage,
//   decryptedSymmetricKey1
// ).toString(CryptoJS.enc.Utf8);

// const decryptedSymmetricKey2 = ethers.utils.toUtf8String(
//   ethers.utils.decrypt(privateKey2, encryptedKey2)
// );
// const decryptedMessage2 = CryptoJS.AES.decrypt(
//   encryptedMessage,
//   decryptedSymmetricKey2
// ).toString(CryptoJS.enc.Utf8);

// console.log("Decrypted message (recipient 1):", decryptedMessage1);
// console.log("Decrypted message (recipient 2):", decryptedMessage2);
