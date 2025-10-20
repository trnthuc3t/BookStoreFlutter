import 'package:flutter/material.dart';
import '../models/address.dart';

class AddressListWidget extends StatelessWidget {
  final List<Address> addresses;
  final Function(Address) onAddressSelected;
  final Function(int addressId) onAddressDeleted;
  final Function(Address) onAddressEdited;

  const AddressListWidget({
    super.key,
    required this.addresses,
    required this.onAddressSelected,
    required this.onAddressDeleted,
    required this.onAddressEdited,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: addresses.length,
      itemBuilder: (context, index) {
        final address = addresses[index];
        return _buildAddressCard(context, address);
      },
    );
  }

  Widget _buildAddressCard(BuildContext context, Address address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onAddressSelected(address),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address.name ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onAddressEdited(address);
                          break;
                        case 'delete':
                          onAddressDeleted(address.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    address.phone ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address.address ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
