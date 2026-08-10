import re

filepath = r"d:\sakil\mess_finder\lib\features\bachelor\views\my_bookings_screen.dart"

with open(filepath, "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace('''        ],
      ),
    ); // Close Container
    ); // Close Dismissible
      },
    );
  }
}''', 
'''        ],
      ),
    ),
  );
      },
    );
  }
}''')

with open(filepath, "w", encoding="utf-8") as f:
    f.write(content)

print("Done")
