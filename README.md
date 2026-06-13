# Mi Tienda — Flutter Cupertino

Aplicacion de gestion de inventario personal desarrollada con Flutter usando widgets **Cupertino** (estilo iOS). Proyecto de la Semana 12 del curso de Aplicaciones Moviles Multiplataforma — TECSUP.

## Caracteristicas

- **Autenticacion local** — login/registro por correo y contrasena, persistido en el dispositivo.
- **Gestion de productos** — crear, ver, editar y eliminar productos con nombre, categoria, precio, stock y descripcion.
- **Perfil de usuario** — editar nombres, apellidos, fecha de nacimiento y correo electronico.
- **Persistencia** — todos los datos se guardan con `shared_preferences` (sin backend).
- **UI Cupertino** — navegacion por tabs, navigation bars con large title, formularios y dialogs al estilo iOS.

## Pantallas

| Pantalla | Descripcion |
|---|---|
| Login | Ingreso con email/contrasena; crea cuenta automaticamente si es nuevo usuario |
| Inicio | Dashboard con accesos rapidos y resumen del usuario |
| Productos | Listado con edicion y eliminacion de productos |
| Perfil | Vista y edicion de datos personales con date picker nativo |

## Tecnologias

- [Flutter](https://flutter.dev) 3.x
- Dart SDK `^3.11.4`
- [`cupertino_icons`](https://pub.dev/packages/cupertino_icons) `^1.0.8`
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) `^2.3.0`

## Requisitos previos

- Flutter SDK instalado ([instrucciones](https://docs.flutter.dev/get-started/install))
- Dart `>=3.11.4`
- Android Studio / Xcode segun plataforma objetivo

## Instalacion y ejecucion

```bash
# 1. Clonar el repositorio
git clone <url-del-repo>
cd cupertino

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar la app
flutter run
```

Para correr en un dispositivo especifico:

```bash
flutter devices              # listar dispositivos disponibles
flutter run -d <device-id>   # e.g. flutter run -d chrome
```

## Estructura del proyecto

```
lib/
└── main.dart          # Modelos, estado global y toda la UI

android/               # Configuracion Android
ios/                   # Configuracion iOS
web/                   # Configuracion Web
windows/               # Configuracion Windows
macos/                 # Configuracion macOS
linux/                 # Configuracion Linux
```

## Autor

Juan Aguirre — TECSUP, 5to ciclo, 2025
