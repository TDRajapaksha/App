import 'package:flutter/material.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        backgroundColor: const Color(0xFF004C99),
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Your wishlist is empty.')),
    );
  }
}
