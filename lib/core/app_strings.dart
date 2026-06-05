// ── Utsob — Bilingual Strings (English / Bengali) ────────────────────────────
// Usage:
//   AppStrings.of(context).findVendors
//   or statically: AppStrings.current.findVendors
//
// Toggle language: AppStrings.setLanguage('bn') or ('en')
// Wrap your MaterialApp with a ValueListenableBuilder on AppStrings.languageNotifier.

import 'package:flutter/foundation.dart';

class AppStrings {
  static final ValueNotifier<String> languageNotifier = ValueNotifier('en');

  static String get _lang => languageNotifier.value;

  static void setLanguage(String lang) {
    assert(lang == 'en' || lang == 'bn', 'Unsupported language: $lang');
    languageNotifier.value = lang;
  }

  static bool get isBengali => _lang == 'bn';

  // Helper: pick string based on current language
  static String _t(String en, String bn) => _lang == 'bn' ? bn : en;

  // ── App name ────────────────────────────────────────────────────────────────
  static String get appName       => _t('Utsob', 'উৎসব');
  static String get appTagline    => _t('Your Celebration, Your Budget', 'আপনার উৎসব, আপনার বাজেট');

  // ── Navigation ──────────────────────────────────────────────────────────────
  static String get home          => _t('Home', 'হোম');
  static String get myPosts       => _t('My Posts', 'আমার পোস্ট');
  static String get budget        => _t('Budget', 'বাজেট');
  static String get profile       => _t('Profile', 'প্রোফাইল');
  static String get browse        => _t('Browse', 'ব্রাউজ');
  static String get myBids        => _t('My Bids', 'আমার বিড');
  static String get messages      => _t('Messages', 'বার্তা');
  static String get bookings      => _t('Bookings', 'বুকিং');

  // ── Host ────────────────────────────────────────────────────────────────────
  static String get findVendors   => _t('Find Vendors', 'ভেন্ডর খুঁজুন');
  static String get searchByBudget=> _t('Search by Budget', 'বাজেট অনুযায়ী খুঁজুন');
  static String get planDreamWedding => _t('Plan Your Dream Celebration', 'স্বপ্নের উৎসব পরিকল্পনা করুন');
  static String get postEvent     => _t('Post an Event', 'ইভেন্ট পোস্ট করুন');
  static String get recentPosts   => _t('Recent Posts', 'সাম্প্রতিক পোস্ট');
  static String get openPosts     => _t('Open Posts', 'খোলা পোস্ট');
  static String get totalBids     => _t('Total Bids', 'মোট বিড');
  static String get hostDashboard => _t('Host Dashboard', 'হোস্ট ড্যাশবোর্ড');

  // ── Vendor ──────────────────────────────────────────────────────────────────
  static String get vendorPortal  => _t('Vendor Portal', 'ভেন্ডর পোর্টাল');
  static String get myPackages    => _t('My Packages', 'আমার প্যাকেজ');
  static String get addPackage    => _t('Add Package', 'প্যাকেজ যোগ করুন');
  static String get myMenus       => _t('My Menus', 'আমার মেনু');
  static String get addMenu       => _t('Add Menu', 'মেনু যোগ করুন');
  static String get discountsOffers => _t('Discounts & Offers', 'ছাড় ও অফার');
  static String get editProfile   => _t('Edit Profile', 'প্রোফাইল সম্পাদনা');
  static String get businessName  => _t('Business Name', 'ব্যবসার নাম');
  static String get bio           => _t('Bio / About', 'পরিচিতি');
  static String get portfolio     => _t('Portfolio Photos', 'পোর্টফোলিও ছবি');
  static String get coverPhoto    => _t('Cover Photo', 'কভার ফটো');
  static String get priceRange    => _t('Price Range', 'মূল্য পরিসর');
  static String get capacity      => _t('Capacity', 'ধারণক্ষমতা');
  static String get specialties   => _t('Specialties', 'বিশেষত্ব');
  static String get availability  => _t('Availability', 'প্রাপ্যতা');
  static String get pendingApproval => _t('Pending Approval', 'অনুমোদনের অপেক্ষায়');
  static String get profileApproved => _t('Profile Approved', 'প্রোফাইল অনুমোদিত');

  // ── Categories ──────────────────────────────────────────────────────────────
  static String get all           => _t('All', 'সব');
  static String get venue         => _t('Venue', 'ভেন্যু');
  static String get catering      => _t('Catering', 'ক্যাটারিং');
  static String get photography   => _t('Photography', 'ফটোগ্রাফি');
  static String get decor         => _t('Decor', 'সাজসজ্জা');
  static String get makeup        => _t('Makeup', 'মেকআপ');
  static String get attireJewelry => _t('Attire & Jewelry', 'পোশাক ও গয়না');
  static String get logistics     => _t('Logistics', 'লজিস্টিক্স');

  // ── Chat ────────────────────────────────────────────────────────────────────
  static String get chat          => _t('Chat', 'চ্যাট');
  static String get typeMessage   => _t('Type a message...', 'বার্তা লিখুন...');
  static String get send          => _t('Send', 'পাঠান');
  static String get noMessages    => _t('No messages yet', 'এখনো কোনো বার্তা নেই');
  static String get startChat     => _t('Start a conversation', 'কথোপকথন শুরু করুন');
  static String get messageFlagged => _t(
    'Message blocked: links and phone numbers are not allowed.',
    'বার্তা ব্লক হয়েছে: লিঙ্ক এবং ফোন নম্বর অনুমোদিত নয়।',
  );
  static String get today         => _t('Today', 'আজ');
  static String get yesterday     => _t('Yesterday', 'গতকাল');

  // ── Booking ──────────────────────────────────────────────────────────────────
  static String get bookNow       => _t('Book Now', 'এখনই বুক করুন');
  static String get confirmBooking => _t('Confirm Booking', 'বুকিং নিশ্চিত করুন');
  static String get eventDate     => _t('Event Date', 'ইভেন্টের তারিখ');
  static String get agreedAmount  => _t('Agreed Amount', 'সম্মত মূল্য');
  static String get selectPackage => _t('Select Package', 'প্যাকেজ নির্বাচন করুন');
  static String get bookingConfirmed => _t('Booking Confirmed!', 'বুকিং নিশ্চিত!');
  static String get awaitingVendor => _t('Awaiting vendor confirmation', 'ভেন্ডরের নিশ্চিতকরণের অপেক্ষায়');
  static String get paymentPending => _t('Payment Pending', 'পেমেন্ট বাকি');
  static String get paymentPartial => _t('Partially Paid', 'আংশিক পরিশোধ');
  static String get paymentPaid   => _t('Fully Paid', 'সম্পূর্ণ পরিশোধ');
  static String get recordPayment => _t('Record Payment', 'পেমেন্ট রেকর্ড করুন');

  // ── Search ───────────────────────────────────────────────────────────────────
  static String get searchVendors => _t('Search Vendors', 'ভেন্ডর অনুসন্ধান');
  static String get filterByCategory => _t('Filter by Category', 'ক্যাটাগরি অনুযায়ী ফিল্টার');
  static String get filterByBudget => _t('Filter by Budget', 'বাজেট অনুযায়ী ফিল্টার');
  static String get sortBy        => _t('Sort by', 'সাজানোর ধরন');
  static String get rating        => _t('Rating', 'রেটিং');
  static String get experience    => _t('Experience', 'অভিজ্ঞতা');
  static String get priceLowHigh  => _t('Price: Low to High', 'মূল্য: কম থেকে বেশি');
  static String get priceHighLow  => _t('Price: High to Low', 'মূল্য: বেশি থেকে কম');
  static String get noVendorsFound => _t(
    'No vendors found for your budget',
    'আপনার বাজেটে কোনো ভেন্ডর পাওয়া যায়নি',
  );
  static String get viewProfile   => _t('View Profile', 'প্রোফাইল দেখুন');

  // ── Admin ────────────────────────────────────────────────────────────────────
  static String get vendorApproval => _t('Vendor Approvals', 'ভেন্ডর অনুমোদন');
  static String get approve        => _t('Approve', 'অনুমোদন করুন');
  static String get reject         => _t('Reject', 'প্রত্যাখ্যান করুন');
  static String get chatMonitor    => _t('Chat Monitor', 'চ্যাট মনিটর');
  static String get flaggedMessages => _t('Flagged Messages', 'চিহ্নিত বার্তা');

  // ── Common ───────────────────────────────────────────────────────────────────
  static String get save           => _t('Save', 'সংরক্ষণ করুন');
  static String get cancel         => _t('Cancel', 'বাতিল');
  static String get confirm        => _t('Confirm', 'নিশ্চিত করুন');
  static String get loading        => _t('Loading...', 'লোড হচ্ছে...');
  static String get errorOccurred  => _t('An error occurred', 'একটি ত্রুটি ঘটেছে');
  static String get retry          => _t('Retry', 'আবার চেষ্টা করুন');
  static String get bdtSymbol      => '৳';
  static String get perHead        => _t('/ person', '/ জন');
  static String get guests         => _t('guests', 'জন');
  static String get years          => _t('years', 'বছর');
  static String get reviews        => _t('reviews', 'রিভিউ');
  static String get bookingsCount  => _t('bookings', 'বুকিং');
  static String get switchToBengali => 'বাংলা';
  static String get switchToEnglish => 'English';
}
