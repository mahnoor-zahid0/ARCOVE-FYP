import 'package:flutter/material.dart';
import 'package:sample/property%20details.dart';

class PropertyPage extends StatelessWidget {
  final List<Property> properties = [
    Property(
      agentImageUrl: 'assets/anas/contact/contact.jpeg', // Anas's contact image
      title: 'Anas\'s Premium House',
      address: '123 Elite Street, New York, NY',
      price: '\$1,200,000',
      bedrooms: 5,
      bathrooms: 4,
      area: 700,
      imageUrl: 'assets/Anas/property/34N1002.jpg', // Image from assets
      description: 'A luxurious five-bedroom house with modern facilities located in New York.',
    ),
    Property(
      agentImageUrl: 'assets/anas/contact/contact.jpeg', // Anas's contact image
      title: 'Anas\'s Cozy Apartment',
      address: '345 Park Avenue, Los Angeles, CA',
      price: '\$900,000',
      bedrooms: 3,
      bathrooms: 2,
      area: 500,
      imageUrl: 'assets/Anas/property/35a6fa4c-6df8-4e2c-aac1-291580c6717e.jpg', // Image from assets
      description: 'A cozy three-bedroom apartment in the heart of Los Angeles.',
    ),
    Property(
      agentImageUrl: 'assets/anas/contact/contact.jpeg', // Anas's contact image
      title: 'Anas\'s Family Home',
      address: '789 Maple Street, Chicago, IL',
      price: '\$700,000',
      bedrooms: 4,
      bathrooms: 3,
      area: 600,
      imageUrl: 'assets/Anas/property/vacant-land-management-reclamation-plot-260nw-2280215221.jpg', // Image from assets
      description: 'A beautiful family home in a quiet neighborhood in Chicago.',
    ),
    Property(
      agentImageUrl: 'assets/waqar/contact/contact.jpeg', // Waqar's contact image
      title: 'Waqar\'s Beach Villa',
      address: 'Beach Road, Miami, FL',
      price: '\$1,500,000',
      bedrooms: 6,
      bathrooms: 5,
      area: 900,
      imageUrl: 'assets/waqar/property/11MarlaShandaar-Homes.png', // Image from assets
      description: 'A luxurious beach villa with stunning ocean views, perfect for relaxation.',
    ),
    Property(
      agentImageUrl: 'assets/waqar/contact/contact.jpeg', // Waqar's contact image
      title: 'Waqar\'s Modern House',
      address: '567 Ocean Drive, San Francisco, CA',
      price: '\$1,000,000',
      bedrooms: 4,
      bathrooms: 4,
      area: 800,
      imageUrl: 'assets/waqar/property/34N1002.jpg', // Image from assets
      description: 'A modern four-bedroom house located in the heart of San Francisco.',
    ),
    Property(
      agentImageUrl: 'assets/waqar/contact/contact.jpeg', // Waqar's contact image
      title: 'Waqar\'s Mountain Retreat',
      address: 'Mountain View, Denver, CO',
      price: '\$800,000',
      bedrooms: 3,
      bathrooms: 3,
      area: 600,
      imageUrl: 'assets/waqar/property/green-acre-grey-structure.webp', // Image from assets
      description: 'A beautiful mountain retreat perfect for outdoor enthusiasts and nature lovers.',
    ),
  ];

  PropertyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by location',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Icon(Icons.filter_list, color: Colors.black),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filters Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                FilterChip(label: const Text('All Filters'), onSelected: (val) {}),
                const SizedBox(width: 8),
                FilterChip(label: const Text('2 Bedrooms'), onSelected: (val) {}),
                const SizedBox(width: 8),
                FilterChip(label: const Text('Area'), onSelected: (val) {}),
                const SizedBox(width: 8),
                FilterChip(label: const Text('Price'), onSelected: (val) {}),
              ],
            ),
          ),
          // Sorting and View Options
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('Sorting: '),
                    Text(
                      'Recent first',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Icon(Icons.arrow_drop_down),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.view_list, color: Colors.green),
                    Icon(Icons.view_module),
                  ],
                ),
              ],
            ),
          ),
          // Properties List
          Expanded(
            child: ListView.builder(
              itemCount: properties.length,
              itemBuilder: (context, index) {
                return PropertyTile(property: properties[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
class PropertyTile extends StatelessWidget {
  final Property property;

  const PropertyTile({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to PropertyDetailsPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PropertyDetailsPage(property: property),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
                    child: Image.asset(
                      property.imageUrl,
                      height: 150,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/error_image.png', // Add an error image in your assets
                          height: 150,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      },
                    ),
                  ),
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.favorite_border, color: Color(0xFFB46146)),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage(property.agentImageUrl),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            property.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8.0),
                          Text(property.address),
                          const SizedBox(height: 8.0),
                          Text(
                            property.price,
                            style: const TextStyle(fontSize: 16, color: Color(0xFFB46146)),
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.king_bed, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${property.bedrooms}'),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.bathtub, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${property.bathrooms}'),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.square_foot, size: 16),
                                  const SizedBox(width: 4),
                                  Text('${property.area} sqft'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_vert),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Property {
  final String agentImageUrl;
  final String title;
  final String address;
  final String price;
  final int bedrooms;
  final int bathrooms;
  final int area;
  final String imageUrl;
  final String description;

  Property({
    required this.agentImageUrl,
    required this.title,
    required this.address,
    required this.price,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.imageUrl,
    required this.description,
  });
}
