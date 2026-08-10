import re

filepath = r"d:\sakil\mess_finder\lib\features\bachelor\views\my_bookings_screen.dart"

with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Add primaryColor to _statusColor and _statusBg
content = content.replace('''  Color _statusColor(String status) {''', 
'''  Color _statusColor(String status) {
    final primaryColor = const Color(0xFF059669);''')

content = content.replace('''  Color _statusBg(String status) {''', 
'''  Color _statusBg(String status) {
    final primaryColor = const Color(0xFF059669);''')


# 2. Fix non-null assertions
content = content.replace('''ownerPhotoUrl != null && ownerPhotoUrl!.isNotEmpty''', '''ownerPhotoUrl != null && ownerPhotoUrl.isNotEmpty''')
content = content.replace('''ownerPhotoUrl == null || ownerPhotoUrl!.isEmpty''', '''ownerPhotoUrl == null || ownerPhotoUrl.isEmpty''')


# 3. Fix line 726 closing bracket
# In my_bookings_screen.dart at the end of _buildBookingCard
# Wait, let's see the end of the file. It's likely _buildBookingCard.
# Let's see the last 15 lines of the file.
# 724:         ],
# 725:       ),
# 726:     );
# 727:       },
# 728:     );
# 729:   }
# 730: }
# This looks like:
# 725:       ),
# 726:     ); // ends the return widget of the builder? But _buildBookingCard is a widget returning method! It doesn't have a builder unless it's an Obx or GetBuilder.

with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)

print("Done")
