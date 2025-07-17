// models/product_input_controllers.dart

import 'package:flutter/material.dart';

class ProductInputControllers {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController quantityController;

  ProductInputControllers()
      : nameController = TextEditingController(),
        descriptionController = TextEditingController(),
        quantityController = TextEditingController();

  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    quantityController.dispose();
  }
}
