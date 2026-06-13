import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appState.load();
  runApp(const MyApp());
}

// ─── Modelos ──────────────────────────────────────────────────────────────────

class Producto {
  int id; String nombre, descripcion, categoria; double precio; int stock;
  Producto({required this.id, required this.nombre, required this.descripcion,
      required this.precio, required this.categoria, required this.stock});
  Map<String, dynamic> toJson() => {'id': id, 'nombre': nombre,
      'descripcion': descripcion, 'precio': precio, 'categoria': categoria, 'stock': stock};
  factory Producto.fromJson(Map<String, dynamic> j) => Producto(
      id: j['id'] as int, nombre: j['nombre'] as String,
      descripcion: j['descripcion'] as String, precio: (j['precio'] as num).toDouble(),
      categoria: j['categoria'] as String, stock: j['stock'] as int);
}

class AccountData {
  String password, nombres, apellidos, fechaNacimiento;
  final List<Producto> productos; int nextId;
  AccountData({required this.password, this.nombres='', this.apellidos='',
      this.fechaNacimiento='', List<Producto>? productos, this.nextId=1})
      : productos = productos ?? [];
  Map<String, dynamic> toJson() => {'password': password, 'nombres': nombres,
      'apellidos': apellidos, 'fechaNacimiento': fechaNacimiento,
      'productos': productos.map((p) => p.toJson()).toList(), 'nextId': nextId};
  factory AccountData.fromJson(Map<String, dynamic> j) => AccountData(
      password: j['password'] as String, nombres: (j['nombres'] as String?) ?? '',
      apellidos: (j['apellidos'] as String?) ?? '',
      fechaNacimiento: (j['fechaNacimiento'] as String?) ?? '',
      productos: (j['productos'] as List?)
              ?.map((p) => Producto.fromJson(p as Map<String, dynamic>)).toList() ?? [],
      nextId: (j['nextId'] as int?) ?? 1);
}

// ─── Estado Global ────────────────────────────────────────────────────────────

final appState = AppState();

class AppState {
  Map<String, AccountData> accounts = {};
  String currentEmail = '';
  AccountData get current => accounts[currentEmail]!;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('accounts');
    if (raw != null) {
      accounts = (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, AccountData.fromJson(v as Map<String, dynamic>)));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accounts', jsonEncode(accounts.map((k, v) => MapEntry(k, v.toJson()))));
  }

  Future<String?> login(String email, String pass) async {
    if (accounts.containsKey(email)) {
      if (accounts[email]!.password != pass) return 'Contrasena incorrecta';
    } else { accounts[email] = AccountData(password: pass); await _save(); }
    currentEmail = email; return null;
  }

  void logout() => currentEmail = '';

  Future<String?> updateProfile({required String nombres, required String apellidos,
      required String fechaNacimiento, required String newEmail}) async {
    if (newEmail != currentEmail && accounts.containsKey(newEmail)) return 'Correo ya en uso';
    final acc = current;
    acc.nombres = nombres; acc.apellidos = apellidos; acc.fechaNacimiento = fechaNacimiento;
    if (newEmail != currentEmail) {
      accounts.remove(currentEmail); accounts[newEmail] = acc; currentEmail = newEmail;
    }
    await _save(); return null;
  }

  Future<void> addProducto({required String nombre, required String descripcion,
      required double precio, required String categoria, required int stock}) async {
    current.productos.add(Producto(id: current.nextId++, nombre: nombre,
        descripcion: descripcion, precio: precio, categoria: categoria, stock: stock));
    await _save();
  }

  Future<void> updateProducto(Producto p) async {
    final i = current.productos.indexWhere((e) => e.id == p.id);
    if (i != -1) current.productos[i] = p;
    await _save();
  }

  Future<void> deleteProducto(int id) async {
    current.productos.removeWhere((e) => e.id == id); await _save();
  }
}

// ─── App ──────────────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => const CupertinoApp(
      title: 'Mi Tienda', debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(primaryColor: CupertinoColors.systemBlue, brightness: Brightness.light),
      home: LoginScreen());
}

void _alert(BuildContext ctx, String msg) => showCupertinoDialog(
    context: ctx,
    builder: (c) => CupertinoAlertDialog(
        title: const Text('Atencion'), content: Text(msg),
        actions: [CupertinoDialogAction(child: const Text('OK'), onPressed: () => Navigator.pop(c))]));

// ─── Login ────────────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true, _loading = false;

  Future<void> _login() async {
    if (_email.text.trim().isEmpty || _pass.text.isEmpty) {
      _alert(context, 'Ingresa email y contrasena'); return;
    }
    setState(() => _loading = true);
    final err = await appState.login(_email.text.trim(), _pass.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) { _alert(context, err); return; }
    Navigator.of(context, rootNavigator: true).pushReplacement(
        CupertinoPageRoute(builder: (_) => const MainTabScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(children: [
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF005EC9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: const Color(0xFF007AFF).withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: const Icon(CupertinoIcons.bag_fill, size: 46, color: CupertinoColors.white),
          ),
          const SizedBox(height: 28),
          const Text('Mi Tienda', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.8)),
          const SizedBox(height: 6),
          Text('Inicia sesion para continuar', style: TextStyle(fontSize: 15, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
          const SizedBox(height: 36),
          Container(
            decoration: BoxDecoration(color: CupertinoColors.systemBackground.resolveFrom(context), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              CupertinoTextField(
                controller: _email, placeholder: 'Correo electronico',
                keyboardType: TextInputType.emailAddress, autocorrect: false, textInputAction: TextInputAction.next,
                prefix: const Padding(padding: EdgeInsets.only(left: 14), child: Icon(CupertinoIcons.mail, color: CupertinoColors.systemBlue, size: 20)),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10), decoration: const BoxDecoration(),
              ),
              Container(height: 0.5, margin: const EdgeInsets.only(left: 46), color: CupertinoColors.separator),
              CupertinoTextField(
                controller: _pass, placeholder: 'Contrasena', obscureText: _obscure, onSubmitted: (_) => _login(),
                prefix: const Padding(padding: EdgeInsets.only(left: 14), child: Icon(CupertinoIcons.lock, color: CupertinoColors.systemBlue, size: 20)),
                suffix: CupertinoButton(padding: const EdgeInsets.only(right: 10),
                    onPressed: () => setState(() => _obscure = !_obscure),
                    child: Icon(_obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash, color: CupertinoColors.systemGrey, size: 20)),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10), decoration: const BoxDecoration(),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Text('Primera vez: se crea tu cuenta automaticamente',
              style: TextStyle(fontSize: 12, color: CupertinoColors.secondaryLabel.resolveFrom(context)), textAlign: TextAlign.center),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, child: CupertinoButton.filled(
            onPressed: _loading ? null : _login, borderRadius: BorderRadius.circular(12),
            child: _loading ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text('Iniciar Sesion', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          )),
        ]),
      ))),
    );
  }

  @override void dispose() { _email.dispose(); _pass.dispose(); super.dispose(); }
}

// ─── Tabs ──────────────────────────────────────────────────────────────────────

class MainTabScreen extends StatelessWidget {
  const MainTabScreen({super.key});
  @override
  Widget build(BuildContext context) => CupertinoTabScaffold(
    tabBar: CupertinoTabBar(activeColor: CupertinoColors.systemBlue, items: const [
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.house_fill), label: 'Inicio'),
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.bag_fill), label: 'Productos'),
      BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_fill), label: 'Perfil'),
    ]),
    tabBuilder: (ctx, i) => CupertinoTabView(
        builder: (_) => [const HomeTab(), const ProductosTab(), const PerfilScreen()][i]),
  );
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  Widget _tile(BuildContext ctx, IconData icon, Color color, String title, Widget dest) =>
      CupertinoListTile.notched(
        leading: Container(width: 32, height: 32,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: CupertinoColors.white, size: 18)),
        title: Text(title), trailing: const CupertinoListTileChevron(),
        onTap: () => Navigator.push(ctx, CupertinoPageRoute(builder: (_) => dest)),
      );

  @override
  Widget build(BuildContext context) {
    final acc = appState.current;
    final inicial = (acc.nombres.isNotEmpty ? acc.nombres[0] : 'U').toUpperCase();
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(slivers: [
        CupertinoSliverNavigationBar(largeTitle: const Text('Inicio'),
            backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
            border: Border.all(color: CupertinoColors.transparent)),
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF005EC9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: const Color(0xFF007AFF).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Row(children: [
              Container(width: 56, height: 56,
                  decoration: BoxDecoration(color: CupertinoColors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(28)),
                  child: Center(child: Text(inicial, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CupertinoColors.white)))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(acc.nombres.isNotEmpty ? '${acc.nombres} ${acc.apellidos}' : 'Bienvenido',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CupertinoColors.white)),
                Text(appState.currentEmail,
                    style: TextStyle(fontSize: 13, color: CupertinoColors.white.withValues(alpha: 0.8)), overflow: TextOverflow.ellipsis),
              ])),
            ]),
          ),
        )),
        SliverToBoxAdapter(child: CupertinoListSection.insetGrouped(
          header: const Text('ACCESO RAPIDO'),
          children: [
            _tile(context, CupertinoIcons.add, const Color(0xFF34C759), 'Registrar Producto', const ProductoFormScreen()),
            _tile(context, CupertinoIcons.bag_fill, CupertinoColors.systemBlue, 'Ver Productos', const ProductosTab()),
            _tile(context, CupertinoIcons.person_fill, const Color(0xFFFF9500), 'Mi Perfil', const PerfilScreen()),
          ],
        )),
      ]),
    );
  }
}

// ─── Productos Tab ────────────────────────────────────────────────────────────

class ProductosTab extends StatefulWidget {
  const ProductosTab({super.key});
  @override State<ProductosTab> createState() => _ProductosTabState();
}

class _ProductosTabState extends State<ProductosTab> {
  Future<void> _eliminar(Producto p) async {
    final ok = await showCupertinoDialog<bool>(context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Eliminar'),
          content: Text('¿Eliminar "${p.nombre}"?'),
          actions: [
            CupertinoDialogAction(child: const Text('Cancelar'), onPressed: () => Navigator.pop(ctx, false)),
            CupertinoDialogAction(isDestructiveAction: true, child: const Text('Eliminar'), onPressed: () => Navigator.pop(ctx, true)),
          ],
        ));
    if (ok == true) { await appState.deleteProducto(p.id); if (mounted) setState(() {}); }
  }

  @override
  Widget build(BuildContext context) {
    final productos = appState.current.productos;
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: Text('Productos (${productos.length})'),
          backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
          border: Border.all(color: CupertinoColors.transparent),
          trailing: CupertinoButton(padding: EdgeInsets.zero, child: const Icon(CupertinoIcons.add),
              onPressed: () async { await Navigator.push(context, CupertinoPageRoute(builder: (_) => const ProductoFormScreen())); if (mounted) setState(() {}); }),
        ),
        if (productos.isEmpty)
          SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(CupertinoIcons.bag, size: 72, color: CupertinoColors.systemGrey3.resolveFrom(context)),
            const SizedBox(height: 16),
            Text('Sin productos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: CupertinoColors.label.resolveFrom(context))),
            const SizedBox(height: 6),
            Text('Toca + para agregar uno', style: TextStyle(fontSize: 15, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
          ])))
        else
          SliverToBoxAdapter(child: CupertinoListSection.insetGrouped(
            children: productos.map((p) => CupertinoListTile.notched(
              leading: Container(width: 34, height: 34,
                  decoration: BoxDecoration(color: const Color(0xFF007AFF).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text(p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: CupertinoColors.systemBlue)))),
              title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${p.categoria}  ·  S/ ${p.precio.toStringAsFixed(2)}  ·  Stock: ${p.stock}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () async { await Navigator.push(context, CupertinoPageRoute(builder: (_) => ProductoFormScreen(producto: p))); if (mounted) setState(() {}); },
                    child: const Icon(CupertinoIcons.pencil, color: CupertinoColors.systemOrange, size: 20)),
                CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () => _eliminar(p),
                    child: const Icon(CupertinoIcons.delete, color: CupertinoColors.systemRed, size: 20)),
              ]),
              onTap: () async { await Navigator.push(context, CupertinoPageRoute(builder: (_) => DetalleProductoScreen(producto: p))); if (mounted) setState(() {}); },
            )).toList(),
          )),
      ]),
    );
  }
}

// ─── Producto Form — Registrar y Editar ───────────────────────────────────────

class ProductoFormScreen extends StatefulWidget {
  final Producto? producto;
  const ProductoFormScreen({super.key, this.producto});
  @override State<ProductoFormScreen> createState() => _ProductoFormScreenState();
}

class _ProductoFormScreenState extends State<ProductoFormScreen> {
  late final TextEditingController _nombre, _desc, _precio, _cat, _stock;
  bool _loading = false;
  bool get _isNew => widget.producto == null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombre = TextEditingController(text: p?.nombre ?? '');
    _desc   = TextEditingController(text: p?.descripcion ?? '');
    _precio = TextEditingController(text: p != null ? p.precio.toString() : '');
    _cat    = TextEditingController(text: p?.categoria ?? '');
    _stock  = TextEditingController(text: p != null ? p.stock.toString() : '');
  }

  Future<void> _guardar() async {
    final n = _nombre.text.trim(), d = _desc.text.trim(), c = _cat.text.trim();
    final pr = _precio.text.trim(), st = _stock.text.trim();
    if ([n, d, c, pr, st].any((s) => s.isEmpty)) { _alert(context, 'Todos los campos son requeridos'); return; }
    final precio = double.tryParse(pr); if (precio == null) { _alert(context, 'Precio no valido'); return; }
    final stock  = int.tryParse(st);   if (stock == null)  { _alert(context, 'Stock debe ser entero'); return; }
    setState(() => _loading = true);
    if (_isNew) {
      await appState.addProducto(nombre: n, descripcion: d, precio: precio, categoria: c, stock: stock);
    } else {
      await appState.updateProducto(Producto(id: widget.producto!.id, nombre: n, descripcion: d, precio: precio, categoria: c, stock: stock));
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _row(String label, TextEditingController ctrl, String ph, {TextInputType? tipo}) =>
      CupertinoFormRow(prefix: Text(label), child: CupertinoTextField.borderless(
          controller: ctrl, placeholder: ph, textAlign: TextAlign.end,
          keyboardType: tipo, textInputAction: TextInputAction.next));

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isNew ? 'Nuevo Producto' : 'Editar Producto'),
        trailing: _loading ? const CupertinoActivityIndicator()
            : CupertinoButton(padding: EdgeInsets.zero, onPressed: _guardar,
                child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w600))),
      ),
      child: SafeArea(child: ListView(children: [
        CupertinoFormSection.insetGrouped(header: const Text('INFORMACION'), children: [
          _row('Nombre',      _nombre, 'Ej: Laptop Dell'),
          _row('Categoria',   _cat,    'Ej: Electronica'),
          _row('Precio (S/)', _precio, '0.00', tipo: const TextInputType.numberWithOptions(decimal: true)),
          _row('Stock',       _stock,  '0',    tipo: TextInputType.number),
        ]),
        CupertinoFormSection.insetGrouped(header: const Text('DESCRIPCION'), children: [
          CupertinoTextField.borderless(controller: _desc, placeholder: 'Descripcion...', maxLines: 5, padding: const EdgeInsets.all(16)),
        ]),
        const SizedBox(height: 24),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CupertinoButton.filled(
              onPressed: _loading ? null : _guardar, borderRadius: BorderRadius.circular(12),
              child: _loading ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : Text(_isNew ? 'Guardar Producto' : 'Actualizar Producto',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            )),
        const SizedBox(height: 32),
      ])),
    );
  }

  @override void dispose() { _nombre.dispose(); _desc.dispose(); _precio.dispose(); _cat.dispose(); _stock.dispose(); super.dispose(); }
}

// ─── Detalle Producto ─────────────────────────────────────────────────────────

class DetalleProductoScreen extends StatelessWidget {
  final Producto producto;
  const DetalleProductoScreen({super.key, required this.producto});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Detalle'),
        trailing: CupertinoButton(padding: EdgeInsets.zero, child: const Text('Editar'),
            onPressed: () async {
              await Navigator.push(context, CupertinoPageRoute(builder: (_) => ProductoFormScreen(producto: producto)));
              if (context.mounted) Navigator.pop(context);
            }),
      ),
      child: SafeArea(child: ListView(children: [
        const SizedBox(height: 28),
        Center(child: Container(
          width: 84, height: 84,
          decoration: BoxDecoration(color: const Color(0xFF007AFF).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
          child: Center(child: Text(producto.nombre.isNotEmpty ? producto.nombre[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: CupertinoColors.systemBlue))),
        )),
        const SizedBox(height: 14),
        Center(child: Text(producto.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
        const SizedBox(height: 4),
        Center(child: Text(producto.categoria, style: const TextStyle(fontSize: 15, color: CupertinoColors.systemBlue))),
        const SizedBox(height: 24),
        CupertinoListSection.insetGrouped(children: [
          CupertinoListTile.notched(title: const Text('Precio'),
              additionalInfo: Text('S/ ${producto.precio.toStringAsFixed(2)}', style: const TextStyle(color: CupertinoColors.systemGreen))),
          CupertinoListTile.notched(title: const Text('Stock'), additionalInfo: Text('${producto.stock} unidades')),
          CupertinoListTile.notched(title: const Text('Categoria'), additionalInfo: Text(producto.categoria)),
        ]),
        CupertinoFormSection.insetGrouped(header: const Text('DESCRIPCION'), children: [
          Padding(padding: const EdgeInsets.all(16), child: Text(producto.descripcion, style: const TextStyle(fontSize: 15))),
        ]),
        const SizedBox(height: 32),
      ])),
    );
  }
}

// ─── Perfil ───────────────────────────────────────────────────────────────────

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late TextEditingController _nombres, _apellidos, _fecha, _correo;
  bool _editando = false, _loading = false;

  @override void initState() { super.initState(); _initCtrl(); }

  void _initCtrl() {
    final acc = appState.current;
    _nombres   = TextEditingController(text: acc.nombres);
    _apellidos = TextEditingController(text: acc.apellidos);
    _fecha     = TextEditingController(text: acc.fechaNacimiento);
    _correo    = TextEditingController(text: appState.currentEmail);
  }

  void _cancelar() {
    final acc = appState.current;
    _nombres.text = acc.nombres; _apellidos.text = acc.apellidos;
    _fecha.text = acc.fechaNacimiento; _correo.text = appState.currentEmail;
    setState(() => _editando = false);
  }

  Future<void> _guardar() async {
    if ([_nombres, _apellidos, _fecha, _correo].any((c) => c.text.trim().isEmpty)) {
      _alert(context, 'Todos los campos son requeridos'); return;
    }
    setState(() => _loading = true);
    final err = await appState.updateProfile(nombres: _nombres.text.trim(),
        apellidos: _apellidos.text.trim(), fechaNacimiento: _fecha.text.trim(), newEmail: _correo.text.trim());
    if (!mounted) return;
    setState(() { _loading = false; if (err == null) _editando = false; });
    if (err != null) _alert(context, err);
  }

  Future<void> _pickDate() async {
    DateTime sel = DateTime(2000);
    final parts = _fecha.text.split('/');
    if (parts.length == 3) sel = DateTime(int.tryParse(parts[2]) ?? 2000, int.tryParse(parts[1]) ?? 1, int.tryParse(parts[0]) ?? 1);
    await showCupertinoModalPopup(context: context, builder: (ctx) => Container(
      height: 300, color: CupertinoColors.systemBackground.resolveFrom(ctx),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          CupertinoButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(ctx)),
          CupertinoButton(
              child: const Text('Listo', style: TextStyle(fontWeight: FontWeight.w600)),
              onPressed: () { _fecha.text = '${sel.day.toString().padLeft(2, '0')}/${sel.month.toString().padLeft(2, '0')}/${sel.year}'; Navigator.pop(ctx); }),
        ]),
        Expanded(child: CupertinoDatePicker(mode: CupertinoDatePickerMode.date, initialDateTime: sel,
            maximumDate: DateTime.now(), minimumDate: DateTime(1950), onDateTimeChanged: (dt) => sel = dt)),
      ]),
    ));
    setState(() {});
  }

  void _logout() => showCupertinoDialog(context: context, builder: (ctx) => CupertinoAlertDialog(
    title: const Text('Cerrar Sesion'), content: const Text('¿Deseas cerrar sesion?'),
    actions: [
      CupertinoDialogAction(child: const Text('Cancelar'), onPressed: () => Navigator.pop(ctx)),
      CupertinoDialogAction(isDestructiveAction: true, child: const Text('Salir'), onPressed: () {
        Navigator.pop(ctx); appState.logout();
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            CupertinoPageRoute(builder: (_) => const LoginScreen()), (_) => false);
      }),
    ],
  ));

  Widget _infoTile(String label, String val) => CupertinoListTile.notched(
      title: Text(label),
      additionalInfo: Text(val.isNotEmpty ? val : '-',
          style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))));

  Widget _formRow(String label, TextEditingController ctrl, {TextInputType? tipo}) =>
      CupertinoFormRow(prefix: Text(label), child: CupertinoTextField.borderless(
          controller: ctrl, placeholder: label, textAlign: TextAlign.end,
          keyboardType: tipo, textInputAction: TextInputAction.next));

  @override
  Widget build(BuildContext context) {
    final acc = appState.current;
    final inicial = (acc.nombres.isNotEmpty ? acc.nombres[0] : 'U').toUpperCase();
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: const Text('Perfil'),
          backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
          border: Border.all(color: CupertinoColors.transparent),
          trailing: !_editando
              ? CupertinoButton(padding: EdgeInsets.zero, onPressed: () => setState(() => _editando = true), child: const Text('Editar'))
              : null,
        ),
        SliverToBoxAdapter(child: Column(children: [
          const SizedBox(height: 16),
          Center(child: Column(children: [
            Container(
              width: 92, height: 92,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF005EC9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(46),
                boxShadow: [BoxShadow(color: const Color(0xFF007AFF).withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: Center(child: Text(inicial, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: CupertinoColors.white))),
            ),
            const SizedBox(height: 12),
            Text(acc.nombres.isNotEmpty ? '${acc.nombres} ${acc.apellidos}' : 'Usuario',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 3),
            Text(appState.currentEmail, style: const TextStyle(fontSize: 14, color: CupertinoColors.systemBlue)),
          ])),
          const SizedBox(height: 28),
          if (!_editando) ...[
            CupertinoListSection.insetGrouped(header: const Text('DATOS PERSONALES'), children: [
              _infoTile('Nombres', acc.nombres),
              _infoTile('Apellidos', acc.apellidos),
              _infoTile('Fecha de Nacimiento', acc.fechaNacimiento),
              _infoTile('Correo', appState.currentEmail),
            ]),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CupertinoButton.filled(onPressed: () => setState(() => _editando = true),
                    borderRadius: BorderRadius.circular(12),
                    child: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.w600)))),
          ] else ...[
            CupertinoFormSection.insetGrouped(header: const Text('DATOS PERSONALES'), children: [
              _formRow('Nombres',   _nombres),
              _formRow('Apellidos', _apellidos),
              CupertinoFormRow(prefix: const Text('Fecha Nac.'), child: CupertinoButton(
                  padding: EdgeInsets.zero, alignment: Alignment.centerRight, onPressed: _pickDate,
                  child: Text(_fecha.text.isNotEmpty ? _fecha.text : 'Seleccionar',
                      style: TextStyle(color: _fecha.text.isNotEmpty
                          ? CupertinoColors.label.resolveFrom(context)
                          : CupertinoColors.placeholderText.resolveFrom(context))))),
              _formRow('Correo', _correo, tipo: TextInputType.emailAddress),
            ]),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
              Expanded(child: CupertinoButton(color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(12), onPressed: _cancelar,
                  child: const Text('Cancelar', style: TextStyle(color: CupertinoColors.label)))),
              const SizedBox(width: 12),
              Expanded(child: CupertinoButton.filled(borderRadius: BorderRadius.circular(12),
                  onPressed: _loading ? null : _guardar,
                  child: _loading ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                      : const Text('Guardar', style: TextStyle(fontWeight: FontWeight.w600)))),
            ])),
          ],
          const SizedBox(height: 32),
          CupertinoListSection.insetGrouped(children: [
            CupertinoListTile.notched(
              leading: Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: CupertinoColors.systemRed, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(CupertinoIcons.square_arrow_left_fill, color: CupertinoColors.white, size: 18)),
              title: const Text('Cerrar Sesion', style: TextStyle(color: CupertinoColors.systemRed)),
              onTap: _logout,
            ),
          ]),
          const SizedBox(height: 32),
        ])),
      ]),
    );
  }

  @override void dispose() { _nombres.dispose(); _apellidos.dispose(); _fecha.dispose(); _correo.dispose(); super.dispose(); }
}
