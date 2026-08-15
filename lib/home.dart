import 'package:flutter/material.dart';
import 'cart.dart';
import 'profile.dart';
import 'product_details.dart';
import 'help_support_page.dart';
import 'user_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';

class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MyHomeBody(),
    const CartPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A0A0A), Color(0xFF004C99), Color(0xFF0A0A0A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.hexagon_outlined,
              color: Colors.blueAccent,
              size: 28,
            ),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.blueAccent, Colors.lightBlueAccent],
              ).createShader(bounds),
              child: const Text(
                "METAL ART",
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Welcome text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                UserSession.userName != null
                    ? 'Hi, ${UserSession.userName}'
                    : '',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
          // Help & Support Icon
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.headset_mic_outlined,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpSupportPage(),
                  ),
                );
              },
              tooltip: 'Help & Support',
            ),
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFF004C99),
          unselectedItemColor: Colors.grey.shade400,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── HOME BODY ───────────────────────────────────────────────────────────────

class MyHomeBody extends StatelessWidget {
  const MyHomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero Banner ──
          Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 240,
                child: Image.asset(
                  'assets/2.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 240,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0A0A0A),
                          Color(0xFF004C99),
                          Color(0xFF0A0A0A),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                height: 240,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "EXCLUSIVE COLLECTION",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Crafted in\nSteel & Fire",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: "Sales",
            subtitle: "30% OFF",
            subtitleColor: const Color(0xFF15B40F),
            onSeeAll: () {},
          ),
          _HorizontalArtList(
            nameColor: const Color(0xFF175C94),
            priceColor: const Color(0xFF15B40F),
            items: const [
              {
                "name": "Art 247",
                "price": "Rs. 2,850",
                "image": "assets/1.jpg",
                "description":
                    "Handcrafted metal art piece #247. Made from premium steel with intricate detailing. Perfect for home or office decor.",
              },
              {
                "name": "Art 583",
                "price": "Rs. 4,200",
                "image": "assets/2.jpg",
                "description":
                    "Handcrafted metal art piece #583. Made from premium steel with intricate detailing. Perfect for home or office decor.",
              },
              {
                "name": "Art 129",
                "price": "Rs. 3,150",
                "image": "assets/3.jpg",
                "description":
                    "Handcrafted metal art piece #129. Made from premium steel with intricate detailing. Perfect for home or office decor.",
              },
              {
                "name": "Art 891",
                "price": "Rs. 5,750",
                "image": "assets/4.jpg",
                "description":
                    "Handcrafted metal art piece #891. Made from premium steel with intricate detailing. Perfect for home or office decor.",
              },
              {
                "name": "Art 456",
                "price": "Rs. 1,999",
                "image": "assets/5.jpg",
                "description":
                    "Handcrafted metal art piece #456. Made from premium steel with intricate detailing. Perfect for home or office decor.",
              },
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: "New Arts",
            subtitle: "Just Arrived",
            subtitleColor: const Color(0xFF7F1794),
            onSeeAll: () {},
          ),
          _HorizontalArtList(
            nameColor: const Color(0xFF360341),
            priceColor: const Color(0xFF1A1A1A),
            items: const [
              {
                "name": "Art 762",
                "price": "Rs. 6,500",
                "image": "assets/6.jpg",
                "description":
                    "Brand new metal art piece #762. A fresh addition to our collection featuring modern geometric patterns.",
              },
              {
                "name": "Art 928",
                "price": "Rs. 7,250",
                "image": "assets/7.jpg",
                "description":
                    "Brand new metal art piece #928. A fresh addition to our collection featuring modern geometric patterns.",
              },
              {
                "name": "Art 551",
                "price": "Rs. 3,890",
                "image": "assets/8.png",
                "description":
                    "Brand new metal art piece #551. A fresh addition to our collection featuring modern geometric patterns.",
              },
              {
                "name": "Art 673",
                "price": "Rs. 8,100",
                "image": "assets/9.png",
                "description":
                    "Brand new metal art piece #673. A fresh addition to our collection featuring modern geometric patterns.",
              },
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: "Animal Arts",
            subtitle: "Wildlife Collection",
            subtitleColor: const Color(0xFF970934),
            onSeeAll: () {},
          ),
          _HorizontalArtList(
            nameColor: const Color(0xFF460308),
            priceColor: const Color(0xFF1A1A1A),
            items: const [
              {
                "name": "Art 185",
                "price": "Rs. 5,200",
                "image": "assets/10.png",
                "description":
                    "Wildlife inspired metal art #185. Beautifully crafted animal silhouette in premium steel.",
              },
              {
                "name": "Art 492",
                "price": "Rs. 6,850",
                "image": "assets/11.png",
                "description":
                    "Wildlife inspired metal art #492. Beautifully crafted animal silhouette in premium steel.",
              },
              {
                "name": "Art 736",
                "price": "Rs. 4,450",
                "image": "assets/1.jpg",
                "description":
                    "Wildlife inspired metal art #736. Beautifully crafted animal silhouette in premium steel.",
              },
              {
                "name": "Art 829",
                "price": "Rs. 7,600",
                "image": "assets/2.jpg",
                "description":
                    "Wildlife inspired metal art #829. Beautifully crafted animal silhouette in premium steel.",
              },
              {
                "name": "Art 367",
                "price": "Rs. 3,250",
                "image": "assets/3.jpg",
                "description":
                    "Wildlife inspired metal art #367. Beautifully crafted animal silhouette in premium steel.",
              },
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ─── SECTION HEADER ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: subtitleColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: subtitleColor,
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: const Row(
              children: [
                Text(
                  "See All",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF004C99),
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 11,
                  color: Color(0xFF004C99),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── HORIZONTAL ART LIST ─────────────────────────────────────────────────────

class _HorizontalArtList extends StatelessWidget {
  final List<Map<String, String>> items;
  final Color nameColor;
  final Color priceColor;

  const _HorizontalArtList({
    required this.items,
    required this.nameColor,
    required this.priceColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 195,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16, right: 6, bottom: 8),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _ArtCard(
            name: items[index]["name"]!,
            price: items[index]["price"]!,
            image: items[index]["image"]!,
            description: items[index]["description"]!,
            nameColor: nameColor,
            priceColor: priceColor,
          );
        },
      ),
    );
  }
}

// ─── ART CARD ────────────────────────────────────────────────────────────────

class _ArtCard extends StatelessWidget {
  final String name;
  final String price;
  final String image;
  final String description;
  final Color nameColor;
  final Color priceColor;

  const _ArtCard({
    required this.name,
    required this.price,
    required this.image,
    required this.description,
    required this.nameColor,
    required this.priceColor,
  });

  @override
  Widget build(BuildContext context) {
    final product = Product(
      image: image,
      title: name,
      price: price,
      description: description,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(product: product),
          ),
        );
      },
      child: Container(
        width: 155,
        margin: const EdgeInsets.only(right: 14, bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.09),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Image.asset(
                image,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 110,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1a1a2e), Color(0xFF0f3460)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white38,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: nameColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: priceColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Add to cart using Supabase
                          _addToCart(context, product);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF004C99),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart(BuildContext context, Product product) async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('itemsT')
          .select('id')
          .eq('item_name', product.title)
          .maybeSingle();

      if (response != null) {
        final productId = response['id'] as int;
        final supabaseService = SupabaseService();
        await supabaseService.addToCart(productId: productId, quantity: 1);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${product.title} added to cart!"),
              backgroundColor: const Color(0xFF004C99),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        // Fallback to local cart
        Cart().add(product);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${product.title} added to cart!"),
              backgroundColor: const Color(0xFF004C99),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Fallback to local cart
      Cart().add(product);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${product.title} added to cart!"),
            backgroundColor: const Color(0xFF004C99),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
