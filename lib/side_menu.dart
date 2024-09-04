import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'handle_logout.dart';
import 'profile_page.dart';
import 'setting_-page.dart';

class SideMenuBar extends StatefulWidget {
  final void Function(bool) updatedTempUnit;
  final VoidCallback? onProfileUpdated;

  const SideMenuBar({
    Key? key,
    required this.updatedTempUnit,
    this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<SideMenuBar> createState() => _SideMenuBarState();
}

class _SideMenuBarState extends State<SideMenuBar> {
  bool isCelsius = true;
  late SharedPreferences _prefs;
  late String _userName = '';
  late String _userSurname = '';
  late String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = _prefs.getString('username') ?? 'John';
      _userSurname = _prefs.getString('surname') ?? 'Doe';
      _userEmail = _prefs.getString('email') ?? 'johndoe@example.com';
    });
  }

  Future<void> _updateProfileData() async {
    await _loadUserData(); // Refresh the user data when profile is updated
    if (widget.onProfileUpdated != null) {
      widget.onProfileUpdated!(); // Notify the parent about profile updates
    }
  }

  void updatedTempUnitt(bool isCelciusC) {
    setState(() {
      widget.updatedTempUnit(isCelciusC);
      isCelsius = isCelciusC;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.orange),
            accountName: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_userName $_userSurname'),
                SizedBox(width: 15),
                // Edit icon or any other icons you want
              ],
            ),
            accountEmail: Text(
              _userEmail,
              style: TextStyle(
                fontSize: 17,
              ),
            ),
            currentAccountPicture: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      onProfileUpdated: () async {
                        await _updateProfileData();
                      },
                    ),
                  ),
                );
                // Notify the parent widget about profile updates
                await _updateProfileData();
              },
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/images/dp.jpg'),
              ),
            ),
          ),
          customListTile(
            icon: Icons.login,
            title: 'My Profile',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    onProfileUpdated: () async {
                      await _updateProfileData();
                    },
                  ),
                ),
              );
            },
          ),
          customListTile(
            icon: Icons.face,
            title: 'Welcome',
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          customListTile(
            icon: Icons.login,
            title: 'setting',
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    onTemperatureUnitChanged: updatedTempUnitt,
                  ),
                ),
              );
              // Notify the parent widget about profile updates
              await _updateProfileData();
            },
          ),
          customListTile(
            icon: Icons.face,
            title: 'Feedback',
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          customListTile(
            icon: Icons.logout,
            title: 'Log Out',
            onTap: () {
              LogoutHandler.showLogoutConfirmation(context);
            },
          ),
          customListTile(
            icon: Icons.info,
            title: 'About',
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget customListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required void Function() onTap,
  }) {
    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 28,
            color: Colors.blueGrey, // Adjust the size here as needed
          ),
          SizedBox(width: 15),
          Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      title: subtitle != null ? Text(subtitle) : null,
      onTap: onTap,
    );
  }
}
