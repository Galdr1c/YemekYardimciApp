import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../models/user_profile.dart';

/// Profile screen for user information and calorie goals
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _calorieGoalController = TextEditingController();
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    // Load profile when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile();
    });
  }

  @override
  void dispose() {
    _ageController.dispose();
    _calorieGoalController.dispose();
    super.dispose();
  }

  void _loadProfileData(ProfileProvider provider) {
    if (provider.profile != null) {
      _ageController.text = provider.profile!.age.toString();
      _calorieGoalController.text = provider.profile!.dailyCalorieGoal.toString();
      _selectedGender = provider.profile!.gender;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<ProfileProvider>();
    final age = int.tryParse(_ageController.text);
    final calorieGoal = int.tryParse(_calorieGoalController.text);

    if (age == null || calorieGoal == null || _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm alanları doldurun'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await provider.saveProfile(
      age: age,
      gender: _selectedGender!,
      dailyCalorieGoal: calorieGoal,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Profil kaydedilemedi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, _) {
          // Load profile data into form when profile is loaded
          if (provider.profile != null && _ageController.text.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadProfileData(provider);
            });
          }

          if (provider.isLoading && provider.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Icon
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Age Field
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(
                      labelText: 'Yaş',
                      hintText: 'Yaşınızı girin',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Yaş gereklidir';
                      }
                      return UserProfile.validateAge(int.tryParse(value));
                    },
                  ),
                  const SizedBox(height: 16),

                  // Gender Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Cinsiyet',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Erkek',
                        child: Text('Erkek'),
                      ),
                      DropdownMenuItem(
                        value: 'Kadın',
                        child: Text('Kadın'),
                      ),
                      DropdownMenuItem(
                        value: 'Diğer',
                        child: Text('Diğer'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value;
                      });
                    },
                    validator: (value) {
                      return UserProfile.validateGender(value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Daily Calorie Goal Field
                  TextFormField(
                    controller: _calorieGoalController,
                    decoration: const InputDecoration(
                      labelText: 'Günlük Kalori Hedefi',
                      hintText: 'Günlük kalori hedefinizi girin',
                      prefixIcon: Icon(Icons.local_fire_department),
                      helperText: '1000-5000 arası bir değer girin',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Günlük kalori hedefi gereklidir';
                      }
                      return UserProfile.validateCalorieGoal(int.tryParse(value));
                    },
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (provider.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        provider.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),

                  // Save Button
                  ElevatedButton(
                    onPressed: provider.isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Kaydet',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Profile Info Card
                  if (provider.profile != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profil Bilgileri',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            _buildInfoRow(
                              context,
                              'Yaş',
                              provider.profile!.age.toString(),
                              Icons.calendar_today,
                            ),
                            const Divider(),
                            _buildInfoRow(
                              context,
                              'Cinsiyet',
                              provider.profile!.gender,
                              Icons.person,
                            ),
                            const Divider(),
                            _buildInfoRow(
                              context,
                              'Günlük Kalori Hedefi',
                              '${provider.profile!.dailyCalorieGoal} kcal',
                              Icons.local_fire_department,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

