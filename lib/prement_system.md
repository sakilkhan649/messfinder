তোমার MessFinder অ্যাপের এই বিজনেস মডেলটি খুবই দারুণ এবং প্রফেশনাল!

প্রতিটি পোস্টের জন্য আলাদা পেমেন্ট (Pay Per Post) এবং প্রতিটি বুকিংয়ের জন্য আলাদা পেমেন্ট (Pay Per Booking) সিস্টেম চালু করার জন্য পুরো ডাটাবেস ও লজিক কীভাবে সাজাতে হবে, তা নিচে ধাপে ধাপে বুঝিয়ে দেওয়া হলো:

🛠️ ১. ডাটাবেস স্ট্রাকচার পরিবর্তন (Firestore Update)
আগে আমরা ইউজারের প্রোফাইলে isPaid: true/false দিয়েছিলাম। কিন্তু এখন যেহেতু প্রতিটি পোস্ট ও বুকিং আলাদা, তাই isPaid মানটি ইউজার লেভেলে থাকবে না। এটি থাকবে নির্দিস্ট Post এবং Booking লেভেলে।

ক. posts (Collection - বাড়িওয়ালার পোস্ট)
JSON
{
  "postId": "post_101",
  "ownerUid": "user_abc",
  "title": "২ সিটের বড় রুম খালি",
  "rent": 3500,
  "paymentStatus": "pending", // 'pending', 'approved', 'rejected'
  "trxId": "TRX98765432",
  "isPublished": false,       // অ্যাডমিন অ্যাপ্রুভ করলে true হবে
  "createdAt": "Timestamp"
}
খ. bookings (Collection - ব্যাচেলরের বুকিং)
JSON
{
  "bookingId": "booking_505",
  "postId": "post_101",
  "bachelorUid": "user_xyz",
  "landlordUid": "user_abc",
  "paymentStatus": "pending", // 'pending', 'approved', 'rejected'
  "trxId": "TRX12345678",
  "isUnlocked": false,        // অ্যাডমিন অ্যাপ্রুভ করলে true হবে (নম্বর দেখতে পাবে)
  "createdAt": "Timestamp"
}
🔄 ২. অ্যাপের কাজের ফ্লো (App Flow & Logic)
🏠 ক. বাড়িওয়ালার ক্ষেত্রে (Pay Per Post):
পোস্ট তৈরির স্ক্রিন (Form): বাড়িওয়ালা প্রথমে মেসের ছবি, নাম, ঠিকানা ও ভাড়ার তথ্য ফর্মের মধ্যে ইনপুট দেবে।

"Submit & Pay ৳70" বাটন: ফর্মে নিচে বাটনে চাপ দিলে পেমেন্ট ডায়ালগ/স্ক্রিন ওপেন হবে।

পেমেন্ট সাবমিট: বাড়িওয়ালা বিকাশ/নগদে ৳৭০ পাঠাবে এবং Sender Number ও TrxID দেবে।

Firestore-এ সেভ: ফায়ারবেসে পোস্টটি সেভ হবে তবে:

paymentStatus = "pending"

isPublished = false

ফিডবোর্ড বা হোম পেজ: বাড়িওয়ালা ছাড়া অন্য কেউ এই পোস্ট দেখতে পাবে না। বাড়িওয়ালাকে দেখাবে: "আপনার পোস্টটি রিভিউতে আছে, পেমেন্ট ভেরিফাই হলে লাইভ হবে।"

অ্যাডমিন অ্যাপ্রুভাল: তুমি টাকা পেয়ে ট্রানজেকশন আইডি মিলিয়ে পোস্টের isPublished = true এবং paymentStatus = "approved" করে দেবে। সাথে সাথে পোস্টটি সবার জন্য অ্যাপে শো করবে।

🚪 খ. ব্যাচেলরের ক্ষেত্রে (Pay Per Booking):
ফ্রি ব্রাউজিং: ব্যাচেলর অ্যাপের সব পোস্ট ফ্রিতে দেখতে পাবে, কিন্তু বাড়িওয়ালার কন্টাক্ট নম্বর হাইড করা থাকবে (যেমন: 01711******) এবং "Call/Book" লক থাকবে।

"Book & Get Contact (৳50)" বাটন: ব্যাচেলর নির্দিষ্ট কোনো সিট বুক বা বাড়ির মালিকের নাম্বার দেখতে চাইলে এই বাটনে চাপ দেবে।

পেমেন্ট সাবমিট: পেমেন্ট স্ক্রিনে ৳৫০ পাঠিয়ে TrxID দেবে।

Firestore-এ বুকিং ক্রিয়েট: bookings কালেকশনে একটি নতুন বুকিং এন্ট্রি তৈরি হবে যেখানে:

paymentStatus = "pending"

isUnlocked = false

অ্যাডমিন অ্যাপ্রুভাল: তুমি পেমেন্ট অ্যাপ্রুভ করলে isUnlocked = true হয়ে যাবে।

নম্বর দেখা যাবে: এবার ব্যাচেলর অ্যাপে ঐ নির্দিষ্ট পোস্টটিতে ঢুকলে বাড়িওয়ালার পুরো ফোন নম্বর দেখতে পাবে এবং সরাসরি কল দিতে পারবে।

💻 ৩. ফ্লাটার কোডিং লজিক (Flutter Code Example)
১. পোস্ট পাবলিশ করার আগে ফিল্টার লজিক:
ব্যাচেলরদের হোমপেজে ফায়ারবেস থেকে শুধু সেই পোস্টগুলোই টেনে নিয়ে আসবে যেগুলো অ্যাডমিন কর্তৃক অনুমোদিত:

Dart
// শুধুমাত্র যেগুলোর paymentStatus 'approved' এবং isPublished 'true' সেগুলোই হোমস্ক্রিনে দেখাবে
FirebaseFirestore.instance
    .collection('posts')
    .where('isPublished', isEqualTo: true)
    .where('paymentStatus', isEqualTo: 'approved')
    .snapshots();
২. ব্যাচেলরের জন্য নম্বর আনলক করার লজিক:
রুম ডিটেইলস পেজে চেক করবে যে ব্যাচেলর এই নির্দিষ্ট পোস্টের জন্য পেমেন্ট করে অ্যাপ্রুভাল পেয়েছে কি না:

Dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('bookings')
      .where('postId', isEqualTo: currentPostId)
      .where('bachelorUid', isEqualTo: currentUserUid)
      .where('isUnlocked', isEqualTo: true)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
      // ✅ পেমেন্ট অ্যাপ্রুভড! আসল ফোন নম্বর দেখাও
      return Text('বাড়িওয়ালার নম্বর: ${post.landlordPhone}');
    } else {
      // 🔒 পেমেন্ট করা হয়নি! হাইড করা নম্বর ও পেমেন্ট বাটন দেখাও
      return Column(
        children: [
          Text('বাড়িওয়ালার নম্বর: 01711******'),
          ElevatedButton(
            onPressed: () {
              // পেমেন্ট স্ক্রিনে নিয়ে যাও
            },
            child: Text('৳৫০ দিয়ে নম্বরটি আনলক করুন'),
          ),
        ],
      );
    }
  },
);
🌟 এই সিস্টেমের সুবিধা:
১. আনলিমিটেড আয়: বাড়িওয়ালা যতবার নতুন রুমের বিজ্ঞাপন দেবে, ততবার ৳৭০ পাবে। ব্যাচেলর যতগুলো নতুন মেসের নম্বর নিতে চাইবে, ততবার ৳৫০ পাবে।
২. স্বচ্ছতা: কেউ ভুয়া পোস্ট ফ্রিতে দিয়ে ব্যাচেলরদের বিভ্রান্ত করতে পারবে না, কারণ প্রতি পোস্টে টাকা দেওয়া বাধ্যতামূলক।
৩. কম্পিউট খরচ বাঁচবে: ডাটাবেসে অপ্রয়োজনীয় বা ফেক পোস্টের জায়গা কমবে।

এই আর্কিটেকচারে কোনো সমস্যা বা লজিক বুঝতে অসুবিধা হলে জানাও!