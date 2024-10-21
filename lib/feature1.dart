
import 'package:flutter/material.dart';
import 'package:sample/product-details.dart';

class DesignDetailsPage extends StatelessWidget {
  final String designName;
  final String designDescription;
  final String designImageUrl;

  DesignDetailsPage({
    super.key,
    required this.designName,
    required this.designDescription,
    required this.designImageUrl,
  });

  // Dummy list of products for demonstration
  final List<Product> products = [
    Product(
      name: 'Design 1',
      description: 'This is a short description of Design 1.',
      imageUrl: 'https://via.placeholder.com/150x150',
      price: 29.99,
      reviews: ['Review 1', 'Review 2'],
    ),
    Product(
      name: 'Design 2',
      description: 'This is a short description of Design 2.',
      imageUrl: 'https://via.placeholder.com/150x150',
      price: 39.99,
      reviews: ['Review 3', 'Review 4'],
    ),
    Product(
      name: 'Design 3',
      description: 'This is a short description of Design 3.',
      imageUrl: 'https://via.placeholder.com/150x150',
      price: 49.99,
      reviews: ['Review 5', 'Review 6'],
    ),
    Product(
      name: 'Design 4',
      description: 'This is a short description of Design 4.',
      imageUrl: 'https://via.placeholder.com/150x150',
      price: 59.99,
      reviews: ['Review 7', 'Review 8'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NEW',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              designName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              designDescription,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Other Designs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailPage(
                            productName: products[index].name,
                            productDescription: products[index].description,
                            productImageUrl: products[index].imageUrl,
                            productPrice: products[index].price,
                            productReviews: products[index].reviews,
                          ),
                        ),
                      );
                    },
                    child: _buildProductListItem(products[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListItem(Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(product.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
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
  final double price;
  final List<String> reviews;

  Product({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.reviews,
  });
}
