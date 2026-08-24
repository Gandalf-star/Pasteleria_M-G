import 'package:flutter/material.dart';

/// Define un campo dinámico para productos de un tipo de negocio específico.
class CampoProducto {
  final String clave;
  final String etiqueta;
  final TipoCampo tipo;
  final List<String>? opciones; // Para campos de tipo selección
  final bool requerido;

  const CampoProducto({
    required this.clave,
    required this.etiqueta,
    this.tipo = TipoCampo.texto,
    this.opciones,
    this.requerido = false,
  });
}

enum TipoCampo { texto, numero, booleano, seleccion }

/// Categorías sugeridas por tipo de negocio de postres.
const Map<String, List<String>> categoriasPorTipo = {
  'pasteleria': ['Tortas', 'Cupcakes', 'Tartas', 'Galletas', 'Bebidas'],
  'heladeria': ['Helados de Crema', 'Helados de Agua', 'Paletas', 'Batidos', 'Toppings'],
  'chocolateria': ['Bombones', 'Barras', 'Trufas', 'Chocolate Caliente'],
  'cafeteria': ['Café', 'Té', 'Repostería', 'Sándwiches Dulces', 'Bebidas Frías'],
  'dulceria': ['Caramelos', 'Gomitas', 'Malvaviscos', 'Dulces Típicos'],
  'vegano': ['Tortas Veganas', 'Helados Sin Lácteos', 'Galletas', 'Bebidas'],
};

/// Campos dinámicos de producto por tipo de negocio.
const Map<String, List<CampoProducto>> camposPorTipo = {
  'pasteleria': [
    CampoProducto(clave: 'ingredientes', etiqueta: 'Ingredientes principales', tipo: TipoCampo.texto),
    CampoProducto(clave: 'porciones', etiqueta: 'Cantidad de porciones', tipo: TipoCampo.numero),
    CampoProducto(clave: 'tiempo_preparacion', etiqueta: 'Tiempo de preparación', tipo: TipoCampo.texto),
    CampoProducto(clave: 'es_sin_gluten', etiqueta: '¿Sin gluten?', tipo: TipoCampo.booleano),
  ],
  'heladeria': [
    CampoProducto(clave: 'sabor', etiqueta: 'Sabor(es)', tipo: TipoCampo.texto),
    CampoProducto(clave: 'presentacion', etiqueta: 'Presentación', tipo: TipoCampo.seleccion, opciones: ['Cono', 'Vaso', 'Litro', 'Medio litro']),
    CampoProducto(clave: 'tipo_helado', etiqueta: 'Tipo', tipo: TipoCampo.seleccion, opciones: ['Crema', 'Agua', 'Yogurt', 'Sorbete']),
  ],
  'chocolateria': [
    CampoProducto(clave: 'tipo_cacao', etiqueta: 'Porcentaje de Cacao', tipo: TipoCampo.texto),
    CampoProducto(clave: 'relleno', etiqueta: 'Relleno', tipo: TipoCampo.texto),
    CampoProducto(clave: 'es_amargo', etiqueta: '¿Es chocolate amargo?', tipo: TipoCampo.booleano),
  ],
  'cafeteria': [
    CampoProducto(clave: 'tipo_bebida', etiqueta: 'Tipo de bebida', tipo: TipoCampo.texto),
    CampoProducto(clave: 'tamano', etiqueta: 'Tamaño', tipo: TipoCampo.seleccion, opciones: ['Pequeño', 'Mediano', 'Grande']),
    CampoProducto(clave: 'temperatura', etiqueta: 'Temperatura', tipo: TipoCampo.seleccion, opciones: ['Caliente', 'Fría', 'Ambas']),
  ],
  'dulceria': [
    CampoProducto(clave: 'sabor_principal', etiqueta: 'Sabor Principal', tipo: TipoCampo.texto),
    CampoProducto(clave: 'peso', etiqueta: 'Peso (gramos)', tipo: TipoCampo.numero),
  ],
  'vegano': [
    CampoProducto(clave: 'ingredientes', etiqueta: 'Ingredientes principales', tipo: TipoCampo.texto),
    CampoProducto(clave: 'endulzante', etiqueta: 'Endulzante utilizado', tipo: TipoCampo.texto),
    CampoProducto(clave: 'es_sin_azucar', etiqueta: '¿Sin azúcar añadida?', tipo: TipoCampo.booleano),
  ],
};

/// Información visual y descriptiva de cada tipo de negocio.
class InfoTipoNegocio {
  final String clave;
  final String etiqueta;
  final IconData icono;

  const InfoTipoNegocio({
    required this.clave,
    required this.etiqueta,
    required this.icono,
  });
}

const List<InfoTipoNegocio> tiposNegocioDisponibles = [
  InfoTipoNegocio(clave: 'pasteleria', etiqueta: 'Pastelería', icono: Icons.cake),
  InfoTipoNegocio(clave: 'heladeria', etiqueta: 'Heladería', icono: Icons.icecream),
  InfoTipoNegocio(clave: 'chocolateria', etiqueta: 'Chocolatería', icono: Icons.cookie), // No hay un buen icono de chocolate, cookie sirve
  InfoTipoNegocio(clave: 'cafeteria', etiqueta: 'Cafetería', icono: Icons.coffee),
  InfoTipoNegocio(clave: 'dulceria', etiqueta: 'Dulcería', icono: Icons.card_giftcard),
  InfoTipoNegocio(clave: 'vegano', etiqueta: 'Postres Veganos', icono: Icons.eco),
];

/// Obtiene la info visual de un tipo de negocio por su clave.
InfoTipoNegocio obtenerInfoTipo(String clave) {
  return tiposNegocioDisponibles.firstWhere(
    (t) => t.clave == clave,
    orElse: () => const InfoTipoNegocio(clave: 'otro', etiqueta: 'Postres Varios', icono: Icons.store),
  );
}
