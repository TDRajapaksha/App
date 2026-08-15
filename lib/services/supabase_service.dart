import 'package:supabase_flutter/supabase_flutter.dart';
import '../user_session.dart';
import 'package:flutter/material.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final supabase = Supabase.instance.client;

  // ─── USER AUTH ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> loginUser(
    String username,
    String password,
  ) async {
    try {
      final response = await supabase
          .from('usersT')
          .select()
          .eq('f_name', username.trim())
          .eq('pw', password.trim())
          .maybeSingle();

      if (response != null) {
        UserSession.userId = response['id'] as String?;
        UserSession.userName = response['f_name'] as String?;
        UserSession.userEmail = response['email'] as String?;
        UserSession.isAdmin = response['is_admin'] as bool? ?? false;
      }
      return response;
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String fName,
    required String email,
    required String password,
    String? lName,
    String? phone,
  }) async {
    try {
      final existing = await supabase
          .from('usersT')
          .select()
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();

      if (existing != null) {
        return {
          'success': false,
          'error': 'Email already registered. Please use a different email.',
        };
      }

      final existingUsername = await supabase
          .from('usersT')
          .select()
          .eq('f_name', fName.trim())
          .maybeSingle();

      if (existingUsername != null) {
        return {
          'success': false,
          'error':
              'Username already taken. Please choose a different username.',
        };
      }

      final response = await supabase.from('usersT').insert({
        'f_name': fName.trim(),
        'l_name': lName?.trim() ?? '',
        'email': email.trim().toLowerCase(),
        'pw': password.trim(),
        'phone': phone?.trim() ?? '',
        'is_admin': false,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      return {
        'success': true,
        'data': response,
        'message': 'Account created successfully!',
      };
    } catch (e) {
      debugPrint('Register error: $e');
      return {
        'success': false,
        'error': 'Registration failed: ${e.toString()}',
      };
    }
  }

  // ─── PRODUCTS ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final response = await supabase
          .from('itemsT')
          .select()
          .eq('is_active', true)
          .order('id');
      return response;
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getProductById(int productId) async {
    try {
      final response = await supabase
          .from('itemsT')
          .select()
          .eq('id', productId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error fetching product: $e');
      return null;
    }
  }

  // ─── ADDRESSES ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUserAddresses() async {
    try {
      final userId = UserSession.userId;
      if (userId == null) return [];

      final response = await supabase
          .from('user_addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false);

      return response;
    } catch (e) {
      debugPrint('Error fetching addresses: $e');
      return [];
    }
  }

  Future<void> addAddress({
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String zipCode,
    required String phone,
    String country = 'Sri Lanka',
    String addressType = 'home',
    bool isDefault = false,
  }) async {
    try {
      final userId = UserSession.userId;
      if (userId == null) throw Exception('User not logged in');

      if (isDefault) {
        await supabase
            .from('user_addresses')
            .update({'is_default': false})
            .eq('user_id', userId);
      }

      await supabase.from('user_addresses').insert({
        'user_id': userId,
        'address_line1': addressLine1,
        'address_line2': addressLine2 ?? '',
        'city': city,
        'state': state,
        'zip_code': zipCode,
        'country': country,
        'phone': phone,
        'address_type': addressType,
        'is_default': isDefault,
      });
    } catch (e) {
      throw Exception('Failed to add address: $e');
    }
  }

  Future<void> updateAddress({
    required int addressId,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String zipCode,
    required String phone,
    String country = 'Sri Lanka',
    String addressType = 'home',
    bool isDefault = false,
  }) async {
    try {
      final userId = UserSession.userId;
      if (userId == null) throw Exception('User not logged in');

      if (isDefault) {
        await supabase
            .from('user_addresses')
            .update({'is_default': false})
            .eq('user_id', userId);
      }

      await supabase
          .from('user_addresses')
          .update({
            'address_line1': addressLine1,
            'address_line2': addressLine2 ?? '',
            'city': city,
            'state': state,
            'zip_code': zipCode,
            'country': country,
            'phone': phone,
            'address_type': addressType,
            'is_default': isDefault,
          })
          .eq('id', addressId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  Future<void> deleteAddress(int addressId) async {
    try {
      final userId = UserSession.userId;
      if (userId == null) throw Exception('User not logged in');

      await supabase
          .from('user_addresses')
          .delete()
          .eq('id', addressId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  // ─── CART ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUserCart() async {
    try {
      final userId = UserSession.userId;
      if (userId == null) return [];

      final response = await supabase
          .from('user_cart')
          .select('*, itemsT(*)')
          .eq('user_id', userId);

      return response;
    } catch (e) {
      debugPrint('Error fetching cart: $e');
      return [];
    }
  }

  Future<void> addToCart({required int productId, int quantity = 1}) async {
    try {
      final userId = UserSession.userId;
      if (userId == null) throw Exception('User not logged in');

      final existing = await supabase
          .from('user_cart')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existing != null) {
        await supabase
            .from('user_cart')
            .update({'quantity': (existing['quantity'] as int) + quantity})
            .eq('id', existing['id']);
      } else {
        await supabase.from('user_cart').insert({
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
        });
      }
    } catch (e) {
      throw Exception('Failed to add to cart: $e');
    }
  }

  Future<void> removeFromCart(int cartItemId) async {
    try {
      final userId = UserSession.userId;
      if (userId == null) throw Exception('User not logged in');

      await supabase
          .from('user_cart')
          .delete()
          .eq('id', cartItemId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to remove from cart: $e');
    }
  }

  Future<void> clearCart() async {
    try {
      final userId = UserSession.userId;
      if (userId == null) throw Exception('User not logged in');

      await supabase.from('user_cart').delete().eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  Future<void> updateCartQuantity(int cartItemId, int quantity) async {
    try {
      final userId = UserSession.userId;
      if (userId == null) throw Exception('User not logged in');

      if (quantity <= 0) {
        await removeFromCart(cartItemId);
        return;
      }

      await supabase
          .from('user_cart')
          .update({'quantity': quantity})
          .eq('id', cartItemId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update cart: $e');
    }
  }

  // ─── ORDERS ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getUserOrders() async {
    try {
      final userId = UserSession.userId;
      if (userId == null) return [];

      final orders = await supabase
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> result = [];
      for (var order in orders) {
        final orderId = order['id'];

        final items = await supabase
            .from('order_items')
            .select()
            .eq('order_id', orderId);

        List<Map<String, dynamic>> itemsWithProducts = [];
        for (var item in items) {
          final productId = item['product_id'];
          final product = await supabase
              .from('itemsT')
              .select()
              .eq('id', productId)
              .maybeSingle();

          itemsWithProducts.add({...item, 'itemsT': product});
        }

        result.add({...order, 'order_items': itemsWithProducts});
      }

      return result;
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getOrderById(int orderId) async {
    try {
      final userId = UserSession.userId;
      if (userId == null) return null;

      final order = await supabase
          .from('orders')
          .select()
          .eq('id', orderId)
          .eq('user_id', userId)
          .maybeSingle();

      if (order == null) return null;

      final items = await supabase
          .from('order_items')
          .select()
          .eq('order_id', orderId);

      List<Map<String, dynamic>> itemsWithProducts = [];
      for (var item in items) {
        final productId = item['product_id'];
        final product = await supabase
            .from('itemsT')
            .select()
            .eq('id', productId)
            .maybeSingle();

        itemsWithProducts.add({...item, 'itemsT': product});
      }

      return {...order, 'order_items': itemsWithProducts};
    } catch (e) {
      debugPrint('Error fetching order: $e');
      return null;
    }
  }

  Future<void> createOrder({
    required List<Map<String, dynamic>> items,
    required double total,
    required double subtotal,
    required double taxAmount,
    required double shippingAmount,
    required double discountAmount,
    required String shippingAddress,
    String? billingAddress,
    String paymentMethod = 'cash_on_delivery',
  }) async {
    try {
      final userId = UserSession.userId;
      if (userId == null) throw Exception('User not logged in');

      // Determine payment status based on payment method
      String paymentStatus = 'pending';
      if (paymentMethod == 'card' ||
          paymentMethod == 'wallet' ||
          paymentMethod == 'bank_transfer') {
        paymentStatus = 'paid';
      } else {
        paymentStatus = 'pending';
      }

      // Create order with payment info
      final orderResponse = await supabase.from('orders').insert({
        'user_id': userId,
        'total_amount': total,
        'subtotal': subtotal,
        'tax_amount': taxAmount,
        'shipping_amount': shippingAmount,
        'discount_amount': discountAmount,
        'shipping_address': shippingAddress,
        'billing_address': billingAddress ?? shippingAddress,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        'order_status': 'pending',
      }).select();

      final orderId = orderResponse[0]['id'];

      // Create order items
      for (var item in items) {
        String productName = 'Product';
        String? productImage;

        try {
          final product = await supabase
              .from('itemsT')
              .select('item_name, image')
              .eq('id', item['product_id'])
              .maybeSingle();

          if (product != null) {
            productName = product['item_name'] ?? 'Product';
            productImage = product['image'];
          }
        } catch (e) {
          debugPrint('Error fetching product ${item['product_id']}: $e');
        }

        await supabase.from('order_items').insert({
          'order_id': orderId,
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'price': item['price'],
          'discount': item['discount'] ?? 0,
          'total': (item['price'] * item['quantity']) - (item['discount'] ?? 0),
          'product_name': productName,
          'product_image': productImage,
        });
      }

      // ✅ CLEAR CART - Make sure this is called
      await clearCart();

      // ✅ Verify cart is cleared
      final cartAfterClear = await getUserCart();
      debugPrint('Cart after clear: ${cartAfterClear.length} items');

      // Create notification
      await supabase.from('notifications').insert({
        'user_id': userId,
        'title': 'Order Placed',
        'message':
            'Your order #$orderId has been placed successfully! Payment: $paymentMethod',
        'type': 'order',
        'link': '/orders',
      });

      debugPrint('Order $orderId created successfully, cart cleared');
    } catch (e) {
      debugPrint('Error creating order: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  Future<void> cancelOrder(int orderId) async {
    try {
      final userId = UserSession.userId;
      if (userId == null) throw Exception('User not logged in');

      // Check if order exists and belongs to user
      final order = await supabase
          .from('orders')
          .select()
          .eq('id', orderId)
          .eq('user_id', userId)
          .maybeSingle();

      if (order == null) {
        throw Exception('Order not found');
      }

      // Check if order can be cancelled
      final status = order['order_status'] ?? 'pending';
      if (status == 'cancelled') {
        throw Exception('Order is already cancelled');
      }
      if (status == 'delivered' || status == 'shipped') {
        throw Exception(
          'Cannot cancel order that is already shipped or delivered',
        );
      }

      // Update order status to cancelled
      await supabase
          .from('orders')
          .update({
            'order_status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      // Create notification
      await supabase.from('notifications').insert({
        'user_id': userId,
        'title': 'Order Cancelled',
        'message': 'Your order #$orderId has been cancelled.',
        'type': 'order',
        'link': '/orders',
      });
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      final userId = UserSession.userId;
      if (userId == null) throw Exception('User not logged in');

      if (UserSession.isAdmin != true) {
        throw Exception('Only admins can update order status');
      }

      await supabase
          .from('orders')
          .update({
            'order_status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);

      final order = await getOrderById(orderId);
      if (order != null) {
        await supabase.from('notifications').insert({
          'user_id': order['user_id'],
          'title': 'Order Update',
          'message': 'Your order #$orderId status updated to: $status',
          'type': 'order',
          'link': '/orders',
        });
      }
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  // ─── SUPPORT TICKETS ─────────────────────────────────────────────────────

  Future<void> submitSupportTicket({
    required String subject,
    required String message,
    required String category,
    String priority = 'medium',
  }) async {
    try {
      final userId = UserSession.userId;
      final userName = UserSession.userName ?? 'Guest';
      final userEmail = UserSession.userEmail;

      await supabase.from('support_tickets').insert({
        'user_id': userId,
        'user_name': userName,
        'user_email': userEmail,
        'subject': subject,
        'message': message,
        'category': category,
        'priority': priority,
        'status': 'open',
      });
    } catch (e) {
      throw Exception('Failed to submit ticket: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserTickets() async {
    try {
      final userId = UserSession.userId;
      if (userId == null) return [];

      final response = await supabase
          .from('support_tickets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      debugPrint('Error fetching tickets: $e');
      return [];
    }
  }

  Future<void> addTicketResponse({
    required int ticketId,
    required String message,
    String senderType = 'user',
  }) async {
    try {
      final userId = UserSession.userId;
      final userName = UserSession.userName ?? 'User';

      await supabase.from('support_ticket_responses').insert({
        'ticket_id': ticketId,
        'user_id': userId,
        'sender_name': userName,
        'sender_type': senderType,
        'message': message,
      });

      await supabase
          .from('support_tickets')
          .update({'status': 'in_progress'})
          .eq('id', ticketId);
    } catch (e) {
      throw Exception('Failed to add response: $e');
    }
  }

  // ─── WISHLIST ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getWishlist() async {
    try {
      final userId = UserSession.userId;
      if (userId == null) return [];

      final response = await supabase
          .from('wishlist')
          .select('*, itemsT(*)')
          .eq('user_id', userId);

      return response;
    } catch (e) {
      debugPrint('Error fetching wishlist: $e');
      return [];
    }
  }

  Future<void> addToWishlist(int productId) async {
    try {
      final userId = UserSession.userId;
      if (userId == null) throw Exception('User not logged in');

      await supabase.from('wishlist').insert({
        'user_id': userId,
        'product_id': productId,
      });
    } catch (e) {
      throw Exception('Failed to add to wishlist: $e');
    }
  }

  Future<void> removeFromWishlist(int wishlistId) async {
    try {
      final userId = UserSession.userId;
      if (userId == null) throw Exception('User not logged in');

      await supabase
          .from('wishlist')
          .delete()
          .eq('id', wishlistId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to remove from wishlist: $e');
    }
  }

  // ─── NOTIFICATIONS ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final userId = UserSession.userId;
      if (userId == null) return [];

      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  Future<void> markNotificationRead(int notificationId) async {
    try {
      final userId = UserSession.userId;
      if (userId == null) return;

      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      final userId = UserSession.userId;
      if (userId == null) return;

      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error marking all notifications read: $e');
    }
  }

  // ─── COUPONS ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getActiveCoupons() async {
    try {
      final response = await supabase
          .from('coupons')
          .select()
          .eq('is_active', true)
          .gte('end_date', DateTime.now().toIso8601String().split('T')[0])
          .order('discount_value', ascending: false);

      return response;
    } catch (e) {
      debugPrint('Error fetching coupons: $e');
      return [];
    }
  }

  Future<bool> applyCoupon(String code, double orderAmount) async {
    try {
      final userId = UserSession.userId;
      if (userId == null) return false;

      final coupon = await supabase
          .from('coupons')
          .select()
          .eq('code', code.trim().toUpperCase())
          .eq('is_active', true)
          .gte('end_date', DateTime.now().toIso8601String().split('T')[0])
          .maybeSingle();

      if (coupon == null) return false;

      if (coupon['used_count'] >= coupon['usage_limit']) return false;

      if (orderAmount < (coupon['minimum_order_amount'] ?? 0)) return false;

      double discount = 0;
      if (coupon['discount_type'] == 'percentage') {
        discount = orderAmount * (coupon['discount_value'] / 100);
        if (coupon['max_discount_amount'] != null) {
          discount = discount < (coupon['max_discount_amount'] as double)
              ? discount
              : (coupon['max_discount_amount'] as double);
        }
      } else {
        discount = coupon['discount_value'] as double;
      }

      await supabase.from('user_coupons').insert({
        'coupon_id': coupon['id'],
        'user_id': userId,
      });

      await supabase
          .from('coupons')
          .update({'used_count': (coupon['used_count'] as int) + 1})
          .eq('id', coupon['id']);

      return true;
    } catch (e) {
      debugPrint('Error applying coupon: $e');
      return false;
    }
  }
}
