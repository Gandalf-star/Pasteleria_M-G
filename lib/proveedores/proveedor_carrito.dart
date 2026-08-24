import 'package:flutter_riverpod/flutter_riverpod.dart';

class ItemCarrito {
  final Map<String, dynamic> producto;
  int cantidad;

  ItemCarrito({required this.producto, this.cantidad = 1});

  double get subtotal {
    final precio = double.tryParse(producto['precio'].toString()) ?? 0.0;
    return precio * cantidad;
  }
}

class NotificadorCarrito extends Notifier<List<ItemCarrito>> {
  @override
  List<ItemCarrito> build() {
    return [];
  }

  void agregarProducto(Map<String, dynamic> producto) {
    final index = state.indexWhere((item) => item.producto['id'] == producto['id']);

    if (index >= 0) {
      final nuevosItems = [...state];
      nuevosItems[index] = ItemCarrito(
        producto: nuevosItems[index].producto,
        cantidad: nuevosItems[index].cantidad + 1,
      );
      state = nuevosItems;
    } else {
      state = [...state, ItemCarrito(producto: producto)];
    }
  }

  void reducirCantidad(String idProducto) {
    final index = state.indexWhere((item) => item.producto['id'] == idProducto);

    if (index >= 0) {
      final item = state[index];
      if (item.cantidad > 1) {
        final nuevosItems = [...state];
        nuevosItems[index] = ItemCarrito(
          producto: item.producto,
          cantidad: item.cantidad - 1,
        );
        state = nuevosItems;
      } else {
        eliminarProducto(idProducto);
      }
    }
  }

  void eliminarProducto(String idProducto) {
    state = state.where((item) => item.producto['id'] != idProducto).toList();
  }

  void limpiarCarrito() {
    state = [];
  }

  double get total {
    return state.fold(0.0, (sum, item) => sum + item.subtotal);
  }
  
  int get totalItems {
    return state.fold(0, (sum, item) => sum + item.cantidad);
  }
}

final proveedorCarrito = NotifierProvider<NotificadorCarrito, List<ItemCarrito>>(() {
  return NotificadorCarrito();
});
