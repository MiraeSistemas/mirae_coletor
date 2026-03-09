// SISTEMA DE ROTAS
// -----------------
// Rotas no Flutter são como endereços de página.
// Navigator.pushNamed(context, AppRoutes.pluviometro)
// → navega para a tela do pluviômetro.
//
// ABORDAGEM USADA: Named Routes com onGenerateRoute
// Centraliza toda a lógica de navegação aqui.
// Fácil adicionar transições customizadas por rota.
//
// ALTERNATIVA FUTURA: go_router (para rotas com parâmetros
// complexos, deep linking e navegação aninhada)

import 'package:flutter/material.dart';
import 'package:mirae_coletor/presentation/pages/home/home_page.dart';
import '../../presentation/pages/pluviometro/pluviometro_page.dart';

abstract class AppRoutes {
  // Constantes de nome de rota — use sempre estas constantes
  // em vez de strings literais para evitar typos
  static const String home = '/';
  static const String pluviometro = '/pluviometro';
  static const String abastecimento = '/abastecimento';
  static const String sync = '/sync';
  static const String estoque = '/estoque';

  // -------------------------------------------------------
  // onGenerateRoute
  // Chamado pelo MaterialApp para resolver cada rota.
  // Retorna uma Route (que define a tela e a transição).
  // -------------------------------------------------------
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // settings.name → o nome da rota ('/pluviometro' etc)
    // settings.arguments → dados passados com a navegação
    switch (settings.name) {
      case home:
        return _fadeRoute(const HomePage(), settings);

      case pluviometro:
        return _slideRoute(const PluviometroPage(), settings);

      case abastecimento:
        // return _slideRoute(const AbastecimentoPage(), settings);
        return _placeholderRoute('Abastecimento', settings);

      case sync:
        // return _slideRoute(const SyncPage(), settings);
        return _placeholderRoute('Sincronização', settings);

      case estoque:
        // return _slideRoute(const EstoquePage(), settings);
        return _placeholderRoute('Estoque', settings);

      default:
        return _placeholderRoute('Página não encontrada', settings);
    }
  }

  // -------------------------------------------------------
  // TRANSIÇÕES CUSTOMIZADAS
  // PageRouteBuilder permite definir animações de entrada.
  //
  // transitionsBuilder recebe:
  //   animation → valor de 0.0 a 1.0 durante a entrada
  //   child     → o widget da nova tela
  // -------------------------------------------------------

  /// Transição de fade (dissolve) — usada na Home
  static Route _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (_, animation, __, child) {
        // FadeTransition anima a opacidade de 0 → 1
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          ),
          child: child,
        );
      },
    );
  }

  /// Transição de slide da direita — usada nas sub-páginas
  static Route _slideRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 350),
      transitionsBuilder: (_, animation, __, child) {
        // Tween<Offset> define o ponto inicial e final do movimento
        // Offset(1, 0) = começa à direita, Offset(0, 0) = posição final
        final tween = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Rota temporária para páginas ainda não implementadas
  static Route _placeholderRoute(String name, RouteSettings settings) {
    return _slideRoute(
      Scaffold(
        appBar: AppBar(title: Text(name)),
        body: Center(
          child: Text(
            '$name\nem breve...',
            style: const TextStyle(color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      settings,
    );
  }
}
