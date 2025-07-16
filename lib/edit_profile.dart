import 'dart:convert';
import 'dart:io';
import 'package:apk_tb_care/connection.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileEditPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileEditPage({super.key, required this.userData});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _placeOfBirthController;
  late final TextEditingController _passwordController;
  String? _gender;
  File? _profileImage;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _phoneController = TextEditingController(text: widget.userData['phone']);
    _birthDateController = TextEditingController(
      text: DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime.parse(widget.userData['date_of_birth'])),
    );
    _placeOfBirthController = TextEditingController(
      text: widget.userData['place_of_birth'],
    );
    _passwordController = TextEditingController();
    _gender = widget.userData['gender'] == 'L' ? 'Laki-laki' : 'Perempuan';
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(widget.userData['date_of_birth']),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final session = await SharedPreferences.getInstance();
    final token = session.getString('token') ?? '';

    setState(() => _isLoading = true);

    try {
      // Prepare updated data according to API requirements
      final updatedData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'gender': _gender == 'Laki-laki' ? 'L' : 'P',
        'place_of_birth': _placeOfBirthController.text,
        'date_of_birth': _birthDateController.text,
        if (_passwordController.text.isNotEmpty)
          'password': _passwordController.text,
      };

      // Here you would typically make the API call
      // For example:
      final response = await http.put(
        Uri.parse('${Connection.BASE_URL}/profile/update'),
        body: jsonEncode(updatedData),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // if (_profileImage != null) {
      //   var request = http.MultipartRequest(
      //     'POST',
      //     Uri.parse('${Connection.BASE_URL}/profile/photo'),
      //   );
      //   request.files.add(
      //     await http.MultipartFile.fromPath('photo', _profileImage!.path),
      //   );
      //   await request.send();
      // }

      // Return updated data to previous screen
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        Navigator.pop(context, {
          ...updatedData,
          if (_profileImage != null) 'photo_path': _profileImage!.path,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text('Simpan'),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              _profileImage != null
                                  ? FileImage(_profileImage!)
                                  : widget.userData['photo'] != null
                                  ? CachedNetworkImageProvider(
                                    widget.userData['photo'],
                                  )
                                  : null,
                          child:
                              _profileImage == null &&
                                      widget.userData['photo'] == null
                                  ? const Icon(Icons.camera_alt, size: 30)
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap isi nama lengkap';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap isi alamat email';
                          }
                          if (!value.contains('@')) {
                            return 'Email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Telepon',
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap isi nomor telepon';
                          }
                          if (value.length < 10 || value.length > 15) {
                            return 'Panjang nomor 10-15 digit';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Jenis Kelamin',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Laki-laki',
                            child: Text('Laki-laki'),
                          ),
                          DropdownMenuItem(
                            value: 'Perempuan',
                            child: Text('Perempuan'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _gender = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap pilih jenis kelamin';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _birthDateController,
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Lahir',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap pilih tanggal lahir';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _placeOfBirthController,
                        decoration: const InputDecoration(
                          labelText: 'Tempat Lahir',
                          prefixIcon: Icon(Icons.place),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText:
                              'Password Baru (kosongkan jika tidak diubah)',
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 6) {
                            return 'Minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          child: const Text('Simpan Perubahan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
