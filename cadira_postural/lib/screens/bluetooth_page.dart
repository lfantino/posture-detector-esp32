import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import '../services/bluetooth_service.dart';
import '../posture_control.dart';

/// Pantalla de connexió Bluetooth.
/// Permet a l'usuari escanejar, veure dispositius emparellats i connectar-se a l'ESP32.
class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage>
    with SingleTickerProviderStateMixin {
  final BluetoothService _bt = BluetoothService.instance;
  final FlutterBlueClassic _plugin = FlutterBlueClassic();

  List<BluetoothDevice> _bondedDevices = [];
  final Set<BluetoothDevice> _scanResults = {};
  bool _isScanning = false;
  bool _isLoading = true;
  int? _connectingIndex;

  StreamSubscription? _scanSubscription;
  StreamSubscription? _scanningStateSubscription;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    final granted = await _bt.requestPermissions();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cal concedir permisos Bluetooth per continuar'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    // Carregar dispositius emparellats
    final bonded = await _bt.getBondedDevices();

    // Escaneig de dispositius nous
    _scanSubscription = _plugin.scanResults.listen((device) {
      if (mounted) setState(() => _scanResults.add(device));
    });

    _scanningStateSubscription = _plugin.isScanning.listen((scanning) {
      if (mounted) setState(() => _isScanning = scanning);
    });

    if (mounted) {
      setState(() {
        _bondedDevices = bonded;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanSubscription?.cancel();
    _scanningStateSubscription?.cancel();
    if (_isScanning) _plugin.stopScan();
    super.dispose();
  }

  Future<void> _connectToDevice(String address, int index) async {
    setState(() => _connectingIndex = index);

    final success = await _bt.connectToDevice(address);

    if (mounted) {
      setState(() => _connectingIndex = null);

      if (success) {
        // Assegurar que el PostureController usa Bluetooth
        final ctrl = PostureController.instance;
        if (ctrl.currentSource != DataSource.bluetooth) {
          await ctrl.switchSource(DataSource.bluetooth);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connectat a Cadira Postural! 🎉'),
            backgroundColor: Color(0xFFA8D5BA),
          ),
        );
        Navigator.of(context).pop(true); // Tornar al dashboard
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_bt.lastError ?? 'Error de connexió'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startScan() {
    _scanResults.clear();
    _plugin.startScan();
  }

  void _stopScan() {
    _plugin.stopScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1EDE6),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 16,
                              offset: Offset(0, 4))
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Color(0xFF2D3142), size: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Connexió Bluetooth',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142))),
                        Text('Connecta amb la cadira ESP32',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Animated BT icon ────────────────────────────────────────
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFB5A1E5)
                            .withOpacity(0.15 + _pulseController.value * 0.15),
                        const Color(0xFFB5A1E5).withOpacity(0.0),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB5A1E5), Color(0xFF8C82D6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB5A1E5).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _bt.isConnected
                            ? Icons.bluetooth_connected
                            : Icons.bluetooth,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ── Estat actual ────────────────────────────────────────────
            ValueListenableBuilder<BtConnectionState>(
              valueListenable: _bt.connectionState,
              builder: (context, state, _) {
                return _buildStatusChip(state);
              },
            ),

            const SizedBox(height: 20),

            // ── Llista de dispositius ────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFB5A1E5)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Secció: Dispositius Emparellats
                          if (_bondedDevices.isNotEmpty) ...[
                            const Text('DISPOSITIUS EMPARELLATS',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1)),
                            const SizedBox(height: 8),
                            _buildDeviceList(_bondedDevices, isPaired: true),
                            const SizedBox(height: 24),
                          ],

                          // Secció: Dispositius Descoberts
                          if (_scanResults.isNotEmpty) ...[
                            const Text('DISPOSITIUS DESCOBERTS',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1)),
                            const SizedBox(height: 8),
                            _buildDeviceList(_scanResults.toList(),
                                isPaired: false),
                            const SizedBox(height: 24),
                          ],

                          if (_bondedDevices.isEmpty && _scanResults.isEmpty)
                            Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 40),
                                  Icon(Icons.bluetooth_searching,
                                      size: 64,
                                      color: Colors.grey.withOpacity(0.3)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No s\'han trobat dispositius.\n'
                                    'Assegura\'t que l\'ESP32 està encès\n'
                                    'i vinculat des d\'Ajustos → Bluetooth.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),

      // ── FAB per escanejar ──────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_isScanning) {
            _stopScan();
          } else {
            _startScan();
          }
        },
        backgroundColor: const Color(0xFFB5A1E5),
        foregroundColor: Colors.white,
        icon: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
        label: Text(_isScanning ? 'Aturar escaneig' : 'Escanejar dispositius'),
      ),
    );
  }

  Widget _buildStatusChip(BtConnectionState state) {
    Color color;
    IconData icon;
    String label;

    switch (state) {
      case BtConnectionState.connected:
        color = const Color(0xFF2ECC71);
        icon = Icons.check_circle;
        label = 'Connectat';
      case BtConnectionState.connecting:
        color = const Color(0xFFF39C12);
        icon = Icons.sync;
        label = 'Connectant...';
      case BtConnectionState.scanning:
        color = const Color(0xFF3498DB);
        icon = Icons.bluetooth_searching;
        label = 'Escanejant...';
      case BtConnectionState.error:
        color = const Color(0xFFE74C3C);
        icon = Icons.error;
        label = 'Error';
      case BtConnectionState.disconnected:
        color = Colors.grey;
        icon = Icons.bluetooth_disabled;
        label = 'Desconnectat';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDeviceList(List<BluetoothDevice> devices,
      {required bool isPaired}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: devices.asMap().entries.map((entry) {
          final index = entry.key;
          final device = entry.value;
          final isEsp32 =
              device.name?.contains(kEsp32DeviceName) == true;
          final isConnecting = _connectingIndex == index;

          return Column(
            children: [
              if (index > 0) const Divider(height: 1, indent: 60),
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isEsp32
                        ? const Color(0xFFB5A1E5).withOpacity(0.15)
                        : const Color(0xFFF2F0F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isEsp32 ? Icons.chair : Icons.bluetooth,
                    color: isEsp32
                        ? const Color(0xFFB5A1E5)
                        : const Color(0xFF9094A6),
                    size: 22,
                  ),
                ),
                title: Text(
                  device.name ?? 'Dispositiu desconegut',
                  style: TextStyle(
                    fontWeight:
                        isEsp32 ? FontWeight.bold : FontWeight.w500,
                    fontSize: 15,
                    color: const Color(0xFF2D3142),
                  ),
                ),
                subtitle: Text(
                  device.address,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: isConnecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFFB5A1E5),
                        ),
                      )
                    : isEsp32
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFB5A1E5),
                                  Color(0xFF8C82D6)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Connectar',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          )
                        : const Icon(Icons.chevron_right,
                            color: Colors.grey),
                onTap: isConnecting
                    ? null
                    : () => _connectToDevice(device.address, index),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
