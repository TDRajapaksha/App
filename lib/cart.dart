import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_details.dart';
import 'services/supabase_service.dart';
import 'user_session.dart';
import 'orders_page.dart';
import 'saved_addresses_page.dart';

// ✅ Local Cart (Fallback)
class Cart {
  static final Cart _instance = Cart._internal();
  factory Cart() => _instance;
  Cart._internal();

  final List<Product> _items = [];
  List<Product> get items => _items;

  void add(Product product) => _items.add(product);
  void remove(Product product) => _items.remove(product);
  void clear() => _items.clear();

  double getLocalTotal() {
    double total = 0;
    for (var item in _items) {
      final cleaned = item.price.replaceAll(RegExp(r'[^0-9]'), '');
      total += double.tryParse(cleaned) ?? 0;
    }
    return total;
  }
}

// ─── CART PAGE UI ─────────────────────────────────────────────────────────────

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Cart _localCart = Cart();
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  bool _isPlacingOrder = false;
  String _selectedPaymentMethod = 'cash_on_delivery';

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  // ─── LOAD CART ──────────────────────────────────────────────────────────
  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    try {
      final items = await _supabaseService.getUserCart();
      setState(() {
        _cartItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ─── GET TOTAL ──────────────────────────────────────────────────────────
  double get _total {
    double total = 0;

    for (var item in _cartItems) {
      final product = item['itemsT'];
      final price = (product?['price'] ?? 0) as num;
      final quantity = item['quantity'] ?? 1;
      total += price.toDouble() * quantity;
    }

    total += _localCart.getLocalTotal();
    return total;
  }

  // ─── PAYMENT HELPERS ───────────────────────────────────────────────────
  String _getPaymentLabel(String method) {
    switch (method) {
      case 'cash_on_delivery':
        return 'Cash on Delivery';
      case 'card':
        return 'Credit/Debit Card';
      case 'wallet':
        return 'Mobile Wallet';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return 'Cash on Delivery';
    }
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'cash_on_delivery':
        return Icons.payments;
      case 'card':
        return Icons.credit_card;
      case 'wallet':
        return Icons.wallet;
      case 'bank_transfer':
        return Icons.account_balance;
      default:
        return Icons.payments;
    }
  }

  // ─── CHECK ADDRESS AND PLACE ORDER ─────────────────────────────────────
  Future<void> _checkAddressAndPlaceOrder() async {
    if (_cartItems.isEmpty && _localCart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final addresses = await _supabaseService.getUserAddresses();

      if (addresses.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please add a shipping address first'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SavedAddressesPage()),
          ).then((_) => _loadCart());
        }
        return;
      }

      final defaultAddress = addresses.firstWhere(
        (a) => a['is_default'] == true,
        orElse: () => addresses.first,
      );

      if (defaultAddress.isEmpty) {
        if (addresses.isNotEmpty) {
          await _placeOrder(addresses.first);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please add a shipping address'),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SavedAddressesPage(),
              ),
            ).then((_) => _loadCart());
          }
        }
      } else {
        await _placeOrder(defaultAddress);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking address: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── PLACE ORDER ───────────────────────────────────────────────────────
  Future<void> _placeOrder(Map<String, dynamic> address) async {
    setState(() => _isPlacingOrder = true);

    try {
      List<Map<String, dynamic>> orderItems = [];
      double subtotal = 0.0;

      // From Supabase cart
      for (var item in _cartItems) {
        final product = item['itemsT'];
        final price = (product?['price'] ?? 0) as num;
        final quantity = item['quantity'] ?? 1;
        final itemTotal = price * quantity;
        subtotal += itemTotal;

        orderItems.add({
          'product_id': item['product_id'],
          'quantity': quantity,
          'price': price.toDouble(),
          'discount': 0.0,
        });
      }

      // From local cart (fallback)
      for (var product in _localCart.items) {
        final cleaned = product.price.replaceAll(RegExp(r'[^0-9]'), '');
        final price = double.tryParse(cleaned) ?? 0.0;
        subtotal += price;

        try {
          final response = await Supabase.instance.client
              .from('itemsT')
              .select('id')
              .eq('item_name', product.title)
              .maybeSingle();

          if (response != null) {
            orderItems.add({
              'product_id': response['id'],
              'quantity': 1,
              'price': price,
              'discount': 0.0,
            });
          }
        } catch (e) {
          print('Error finding product: $e');
        }
      }

      if (orderItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid items to order'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isPlacingOrder = false);
        return;
      }

      final taxAmount = subtotal * 0.10;
      final shippingAmount = subtotal >= 3000 ? 0.0 : 250.0;
      final discountAmount = 0.0;
      final total = subtotal + taxAmount + shippingAmount;

      final addressString =
          '${address['address_line1']}, ${address['city']}, ${address['state']} ${address['zip_code']}';

      // Create the order
      await _supabaseService.createOrder(
        items: orderItems,
        total: total,
        subtotal: subtotal,
        taxAmount: taxAmount,
        shippingAmount: shippingAmount,
        discountAmount: discountAmount,
        shippingAddress: addressString,
        paymentMethod: _selectedPaymentMethod,
      );

      // ✅ CLEAR LOCAL CART
      _localCart.clear();

      // ✅ CLEAR SUPABASE CART (already handled in createOrder, but let's ensure it's cleared)
      await _supabaseService.clearCart();

      // ✅ RELOAD CART TO REFRESH UI
      await _loadCart();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order placed successfully with ${_getPaymentLabel(_selectedPaymentMethod)}! 🎉',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to orders page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrdersPage()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isPlacingOrder = false);
  }

  // ─── BUILD METHODS ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasItems = _cartItems.isNotEmpty || _localCart.items.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !hasItems
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ..._cartItems.map((item) => _buildCartItem(item)),
                      ..._localCart.items.map(
                        (product) => _buildLocalCartItem(product),
                      ),
                    ],
                  ),
                ),
                _buildCheckoutSection(),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF004C99).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Color(0xFF004C99),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Your Cart is Empty",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add items to your cart to get started",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final product = item['itemsT'];
    final quantity = item['quantity'] ?? 1;
    final price = (product?['price'] ?? 0) as num;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/${product?['image'] ?? '1.jpg'}',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 60,
                height: 60,
                color: const Color(0xFF0f3460),
                child: const Icon(Icons.image_outlined, color: Colors.white38),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?['item_name'] ?? 'Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF15B40F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 20),
                      onPressed: () async {
                        if (quantity > 1) {
                          await _supabaseService.updateCartQuantity(
                            item['id'],
                            quantity - 1,
                          );
                          await _loadCart();
                        }
                      },
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 20),
                      onPressed: () async {
                        await _supabaseService.updateCartQuantity(
                          item['id'],
                          quantity + 1,
                        );
                        await _loadCart();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              await _supabaseService.removeFromCart(item['id']);
              await _loadCart();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocalCartItem(Product product) {
    final cleaned = product.price.replaceAll(RegExp(r'[^0-9]'), '');
    final price = double.tryParse(cleaned) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              product.image,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 60,
                height: 60,
                color: const Color(0xFF0f3460),
                child: const Icon(Icons.image_outlined, color: Colors.white38),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFF15B40F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () {
              setState(() => _localCart.remove(product));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection() {
    final total = _total;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Payment Method Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Payment Method",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                _buildPaymentOption(
                  icon: Icons.payments_outlined,
                  label: "Cash on Delivery",
                  value: 'cash_on_delivery',
                  description: "Pay when you receive your order",
                ),
                _buildPaymentOption(
                  icon: Icons.credit_card_outlined,
                  label: "Credit / Debit Card",
                  value: 'card',
                  description: "Pay securely with your card",
                ),
                _buildPaymentOption(
                  icon: Icons.wallet_outlined,
                  label: "Mobile Wallet",
                  value: 'wallet',
                  description: "Pay with your mobile wallet",
                ),
                _buildPaymentOption(
                  icon: Icons.account_balance_outlined,
                  label: "Bank Transfer",
                  value: 'bank_transfer',
                  description: "Pay via bank transfer",
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Order Summary
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Subtotal",
                      style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                    ),
                    Text(
                      "Rs. ${total.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Shipping",
                      style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                    ),
                    Text(
                      total >= 3000 ? "Free" : "Rs. 250",
                      style: TextStyle(
                        fontSize: 14,
                        color: total >= 3000 ? Colors.green : Color(0xFF666666),
                        fontWeight: total >= 3000
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Tax (10%)",
                      style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                    ),
                    Text(
                      "Rs. ${(total * 0.10).toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      "Rs. ${(total + (total >= 3000 ? 0 : 250) + (total * 0.10)).toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF004C99),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isPlacingOrder ? null : _checkAddressAndPlaceOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004C99),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isPlacingOrder
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Place Order",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getPaymentIcon(_selectedPaymentMethod),
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  _getPaymentLabel(_selectedPaymentMethod),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String label,
    required String value,
    required String description,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF004C99).withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF004C99) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF004C99)
                  : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 14,
                      color: isSelected
                          ? const Color(0xFF004C99)
                          : Colors.black87,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF004C99),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
