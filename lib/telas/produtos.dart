import 'dart:convert';

import 'package:flat_list/flat_list.dart';
import 'package:floricultura/autenticador.dart';
import 'package:flutter/material.dart';
import 'package:floricultura/componentes/produto_card.dart';
import 'package:floricultura/estado.dart';
import 'package:flutter/services.dart';
import 'package:toast/toast.dart';

class Produtos extends StatefulWidget {
  const Produtos({super.key});

  @override
  State<StatefulWidget> createState() {
    return _ProdutosState();
  }
}

const int tamanhoPagina = 4;

class _ProdutosState extends State<Produtos> {
  late dynamic _listaEstatica;
  List<dynamic> _produtos = [];

  int _proximaPagina = 1;
  bool _carregando = false;

  late TextEditingController _controladorFiltragem;
  String _filtro = "";

  @override
  void initState() {
    super.initState();

    ToastContext().init(context);

    _controladorFiltragem = TextEditingController();
    _lerListaEstatica();
    _recuperarUsuarioLogado();
  }

  void _recuperarUsuarioLogado() {
    Autenticador.recuperarUsuario().then((usuario) {
      if (usuario != null) {
        setState(() {
          estadoApp.onLogin(usuario);
        });
      }
    });
  }

  Future<void> _lerListaEstatica() async {
    final String conteudoJson =
        await rootBundle.loadString("lib/recursos/json/lista_produtos.json");
    _listaEstatica = await json.decode(conteudoJson);

    _carregarProdutos();
  }

  void _carregarProdutos() {
    setState(() {
      _carregando = true;
    });

    var maisProdutos = [];
    if (_filtro.isNotEmpty) {
      _listaEstatica["produtos"].where((item) {
        String nome = item["nome"];

        return nome.toLowerCase().contains(_filtro.toLowerCase());
      }).forEach((item) {
        maisProdutos.add(item);
      });
    } else {
      maisProdutos = _produtos;

      final totalProdutosParaCarregar = _proximaPagina * tamanhoPagina;
      if (_listaEstatica["produtos"].length >= totalProdutosParaCarregar) {
        maisProdutos =
            _listaEstatica["produtos"].sublist(0, totalProdutosParaCarregar);
      }
    }

    setState(() {
      _produtos = maisProdutos;
      _proximaPagina = _proximaPagina + 1;

      _carregando = false;
    });
  }

  Future<void> _atualizarProdutos() async {
    _produtos = [];
    _proximaPagina = 1;

    _carregarProdutos();
  }

  @override
  Widget build(BuildContext context) {
    bool usuarioLogado = estadoApp.usuario != null;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green.shade100,
          actions: [
            Expanded(
                child: Padding(
              padding: const EdgeInsets.only(
                  top: 10, bottom: 10, left: 30, right: 20),
              child: TextField(
                controller: _controladorFiltragem,
                onSubmitted: (descricao) {
                  _filtro = descricao;

                  _atualizarProdutos();
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.only(top: 5, left: 8),
                  suffixIcon: Icon(Icons.search),
                  hintText: 'Pesquisar',
                  hintStyle: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w300,
                      color: Colors.black),
                ),
              ),
            )),
            usuarioLogado
                ? IconButton(
                    onPressed: () {
                      Autenticador.logout().then((_) {
                        setState(() {
                          estadoApp.onLogout();
                        });

                        Toast.show("Você não está mais conectado",
                            duration: Toast.lengthLong, gravity: Toast.bottom);
                      });
                    },
                    icon: const Icon(Icons.logout))
                : IconButton(
                    onPressed: () {
                      Autenticador.login().then((usuario) {
                        setState(() {
                          estadoApp.onLogin(usuario);
                        });

                        Toast.show("Você foi conectado com sucesso",
                            duration: Toast.lengthLong, gravity: Toast.bottom);
                      });
                    },
                    icon: const Icon(Icons.person))
          ],
        ),
        body: FlatList(
            data: _produtos,
            numColumns: 1,
            loading: _carregando,
            onRefresh: () {
              _filtro = "";
              _controladorFiltragem.clear();

              return _atualizarProdutos();
            },
            onEndReached: () => _carregarProdutos(),
            buildItem: (item, int indice) {
              return SizedBox(height: 450, child: ProdutoCard(produto: item));
            }));
  }
}
