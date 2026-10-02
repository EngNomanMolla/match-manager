import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'bn_BD': {
          'app_name': 'Match Manager',
          'developed_by': 'Developed by Learn with Noman',
          'developer_credit': 'ডেভেলপমেন্টে: Learn with Noman',
          
          // Navigation
          'nav_home': 'হোম',
          'nav_groups': 'গ্রুপসমূহ',
          'nav_media': 'মিডিয়া',
          'nav_more': 'আরও',
          
          // Search & Filter
          'search_hint': 'ব্যক্তি বা গ্রুপ খুঁজুন...',
          'filter_all': 'সকল',
          'filter_groups': 'গ্রুপ',
          'filter_persons': 'ব্যক্তি',
          
          // Group / Mess
          'my_groups': 'আমার গ্রুপসমূহ',
          'joined_groups': 'যুক্ত থাকা গ্রুপ',
          'create_group': 'নতুন গ্রুপ তৈরি',
          'create_group_btn': 'গ্রুপ তৈরি করুন',
          'join_group': 'গ্রুপে যুক্ত হন',
          'join_with_code': 'গ্রুপ কোড দিয়ে যুক্ত হন',
          'group_name': 'গ্রুপের নাম',
          'group_name_hint': 'যেমন: ধানমন্ডি ব্যাচেলর মেস',
          'group_type': 'গ্রুপের ধরণ',
          'group_code': 'গ্রুপ কোড',
          'description': 'বিবরণ / নিয়মাবলী',
          'description_hint': 'গ্রুপের নিয়ম বা তথ্য লিখুন...',
          'created_at': 'তৈরির তারিখ',
          
          // Members
          'members': 'সদস্যবৃন্দ',
          'total_members': 'মোট সদস্য',
          'add_member': 'সদস্য যুক্ত করুন',
          'edit_member': 'মেম্বার রোল ও তথ্য এডিট',
          'current_role': 'বর্তমান দায়িত্ব',
          'change_role': 'দায়িত্ব পরিবর্তন করুন',
          'user_found': 'ইউজার পাওয়া গেছে!',
          'user_not_found': 'নতুন মেম্বার (নাম লিখুন)',
          'phone_search_hint': 'মোবাইল নম্বর লিখলে নাম অটো চলে আসবে',
          'member_name': 'সদস্যের নাম',
          'member_phone': 'মোবাইল নম্বর',
          'member_phone_hint': '০১XXXXXXXXX',
          'role': 'দায়িত্ব',
          'manager': 'ম্যানেজার',
          'co_manager': 'সহকারী ম্যানেজার',
          'member': 'মেম্বার',
          
          // Types
          'bachelor_mess': 'ব্যাচেলর মেস',
          'hostel_mess': 'হোস্টেল / ফ্ল্যাট',
          'family_mess': 'পারিবারিক মিল',
          'office_mess': 'অফিস লাঞ্চ মেস',
          'custom_mess': 'কাস্টম গ্রুপ',
          
          // Media
          'media_title': 'মিডিয়া ও ডকুমেন্ট',
          'media_subtitle': 'বাজার রশিদ, নোটিশ ও ছবি সমূহ',
          'no_media': 'এখনো কোনো ফাইল বা ছবি নেই',
          'upload_receipt': 'রশিদ বা ছবি আপলোড করুন',
          
          // More / Settings
          'profile': 'প্রোফাইল',
          'edit_profile': 'প্রোফাইল এডিট',
          'user_name': 'আপনার নাম',
          'language': 'ভাষা (Language)',
          'about_app': 'অ্যাপ সম্পর্কে',
          'version': 'ভার্সন ১.০.০',
          
          // Common
          'save': 'সংরক্ষণ',
          'cancel': 'বাতিল',
          'delete': 'মুছে ফেলুন',
          'success': 'সফল হয়েছে',
          'code_copied': 'কোড কপি হয়েছে!',
          'no_data_found': 'কিছু পাওয়া যায়নি',
          'confirm_delete': 'আপনি কি নিশ্চিত মুছে ফেলতে চান?',
          'remove_member': 'মেম্বার রিমুভ করুন',
          'confirm_remove_member': 'আপনি কি নিশ্চিত এই মেম্বারকে গ্রুপ থেকে বাদ দিতে চান?',
          'member_updated_success': 'মেম্বারের দায়িত্ব সফলভাবে আপডেট হয়েছে!',
          'member_added_success': 'সদস্য সফলভাবে যুক্ত হয়েছে!',
        },
        'en_US': {
          'app_name': 'Match Manager',
          'developed_by': 'Developed by Learn with Noman',
          'developer_credit': 'Developed by: Learn with Noman',
          
          // Navigation
          'nav_home': 'Home',
          'nav_groups': 'Groups',
          'nav_media': 'Media',
          'nav_more': 'More',
          
          // Search & Filter
          'search_hint': 'Search person or group...',
          'filter_all': 'All',
          'filter_groups': 'Groups',
          'filter_persons': 'Persons',
          
          // Group / Mess
          'my_groups': 'My Groups',
          'joined_groups': 'Joined Groups',
          'create_group': 'Create New Group',
          'create_group_btn': 'Create Group',
          'join_group': 'Join Group',
          'join_with_code': 'Join with Group Code',
          'group_name': 'Group Name',
          'group_name_hint': 'e.g. Dhanmondi Bachelor Mess',
          'group_type': 'Group Type',
          'group_code': 'Group Code',
          'description': 'Description / Rules',
          'description_hint': 'Write group rules or notes...',
          'created_at': 'Created on',
          
          // Members
          'members': 'Members',
          'total_members': 'Total Members',
          'add_member': 'Add Member',
          'edit_member': 'Edit Member Role & Info',
          'current_role': 'Current Role',
          'change_role': 'Change Role',
          'user_found': 'User Found!',
          'user_not_found': 'New Member (Enter Name)',
          'phone_search_hint': 'Type phone to autofill name',
          'member_name': 'Member Name',
          'member_phone': 'Phone Number',
          'member_phone_hint': '01XXXXXXXXX',
          'role': 'Role',
          'manager': 'Manager',
          'co_manager': 'Co-Manager',
          'member': 'Member',
          
          // Types
          'bachelor_mess': 'Bachelor Mess',
          'hostel_mess': 'Hostel / Flat',
          'family_mess': 'Family Meal',
          'office_mess': 'Office Lunch Mess',
          'custom_mess': 'Custom Group',
          
          // Media
          'media_title': 'Media & Documents',
          'media_subtitle': 'Bazar receipts, notices & images',
          'no_media': 'No media or documents yet',
          'upload_receipt': 'Upload Receipt or Image',
          
          // More / Settings
          'profile': 'Profile',
          'edit_profile': 'Edit Profile',
          'user_name': 'Your Name',
          'language': 'Language (ভাষা)',
          'about_app': 'About App',
          'version': 'Version 1.0.0',
          
          // Common
          'save': 'Save',
          'cancel': 'Cancel',
          'delete': 'Delete',
          'success': 'Success',
          'code_copied': 'Code copied to clipboard!',
          'no_data_found': 'No results found',
          'confirm_delete': 'Are you sure you want to delete?',
          'remove_member': 'Remove Member',
          'confirm_remove_member': 'Are you sure you want to remove this member?',
          'member_updated_success': 'Member role updated successfully!',
          'member_added_success': 'Member added successfully!',
        },
      };
}
