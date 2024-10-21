import 'package:flutter/material.dart';

class ProductDetailPage extends StatelessWidget {
  final String productName;
  final String productDescription;
  final String productImageUrl;
  final double productPrice;
  final List<String> productReviews;

  ProductDetailPage({
    super.key,
    required this.productName,
    required this.productDescription,
    required this.productImageUrl,
    required this.productPrice,
    required this.productReviews,
  });

  // Dummy list of related products for demonstration
  final List<Product> relatedProducts = [
    Product(
      name: 'Related Product 1',
      description: 'Short description of related product 1.',
      imageUrl: 'https://via.placeholder.com/150x150',
    ),
    Product(
      name: 'Related Product 2',
      description: 'Short description of related product 2.',
      imageUrl: 'https://via.placeholder.com/150x150',
    ),
    Product(
      name: 'Related Product 3',
      description: 'Short description of related product 3.',
      imageUrl: 'https://via.placeholder.com/150x150',
    ),
    Product(
      name: 'Related Product 4',
      description: 'Short description of related product 4.',
      imageUrl: 'https://via.placeholder.com/150x150',
    ),
  ];

  void _addToWishlist(BuildContext context, String productName) {
    // Implement the logic to add the product to the wishlist
    print("$productName added to wishlist");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$productName added to wishlist')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(productImageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                productName,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '\$${productPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, color: Colors.green),
              ),
              const SizedBox(height: 16),
              Text(
                productDescription,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reviews',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...productReviews.map((review) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  review,
                  style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                ),
              )),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _addToWishlist(context, productName),
                    icon: const Icon(Icons.favorite),
                    label: const Text("Add to Wishlist"),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Related Products',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: relatedProducts.length,
                itemBuilder: (context, index) {
                  return _buildRelatedProductItem(context, relatedProducts[index]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelatedProductItem(BuildContext context, Product product) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              image: DecorationImage(
                image: NetworkImage(product.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _addToWishlist(context, product.name),
                  icon: const Icon(Icons.favorite),
                  label: const Text("Add to Wishlist"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Product {
  final String name;
  final String description;
  final String imageUrl;

  Product({
    required this.name,
    required this.description,
    required this.imageUrl,
  });
}
