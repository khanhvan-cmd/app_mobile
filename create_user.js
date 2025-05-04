const admin = require('firebase-admin');
     const serviceAccount = require('./path/to/serviceAccountKey.json'); // Thay bằng đường dẫn đến file service account

     admin.initializeApp({
       credential: admin.credential.cert(serviceAccount),
     });

     async function createUser(email, password, username) {
       try {
         const userRecord = await admin.auth().createUser({
           email: email,
           password: password,
           displayName: username,
         });
         console.log('Đã tạo người dùng:', userRecord.uid);
         // Đặt vai trò admin ngay sau khi tạo
         await admin.auth().setCustomUserClaims(userRecord.uid, { role: 'admin' });
         console.log('Đã đặt vai trò admin cho người dùng:', userRecord.uid);
         return userRecord.uid;
       } catch (error) {
         console.error('Lỗi khi tạo người dùng:', error);
       }
     }

     // Tạo người dùng với email khanvnguyen9@gmail.com
     createUser('khanvnguyen9@gmail.com', 'khanvnguyen9', 'unknown').then(() => process.exit());