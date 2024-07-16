import 'dart:convert';

import 'package:flat_list/flat_list.dart';
import 'package:floricultura/estado.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:toast/toast.dart';
import 'package:flutter_share/flutter_share.dart';

class Detalhes extends StatefulWidget {
  const Detalhes({super.key});

  @override
  State<StatefulWidget> createState() {
    return _DetalhesState();
  }
}

enum _EstadoProduto { naoVerificado, temProduto, semProduto }

class _DetalhesState extends State<Detalhes> {
  late dynamic _listaEstatica;
  late dynamic _comentariosEstaticos;

  _EstadoProduto _temProduto = _EstadoProduto.naoVerificado;
  late dynamic _produto;

  late TextEditingController _controladorNovoComentario;

  List<dynamic> _comentarios = [];
  bool _carregandoComentarios = false;
  bool _temComentarios = false;

  late PageController _controladorSlides;
  late int _slideSelecionado;

  bool _curtiu = false;

  @override
  void initState() {
    super.initState();

    ToastContext().init(context);

    _lerListaEstatica();
    _iniciarSlides();

    _controladorNovoComentario = TextEditingController();
  }

  void _iniciarSlides() {
    _slideSelecionado = 0;
    _controladorSlides = PageController(initialPage: _slideSelecionado);
  }

  Future<void> _lerListaEstatica() async {
    String conteudoJson =
        await rootBundle.loadString("lib/recursos/json/lista_produtos.json");
    _listaEstatica = await json.decode(conteudoJson);

    conteudoJson =
        await rootBundle.loadString("lib/recursos/json/comentarios.json");
    _comentariosEstaticos = await json.decode(conteudoJson);

    _carregarProduto();
    _carregarComentarios();
  }

  void _carregarProduto() {
    setState(() {
      _produto = _listaEstatica['produtos']
          .firstWhere((produto) => produto["_id"] == estadoApp.idProduto);

      _temProduto = _produto != null
          ? _EstadoProduto.temProduto
          : _EstadoProduto.semProduto;
    });
  }

  void _carregarComentarios() {
    setState(() {
      _carregandoComentarios = true;
    });

    var maisComentarios = [];
    _comentariosEstaticos["comentarios"].where((item) {
      return item["feed"] == estadoApp.idProduto;
    }).forEach((item) {
      maisComentarios.add(item);
    });

    setState(() {
      _carregandoComentarios = false;
      _comentarios = maisComentarios;

      _temComentarios = _comentarios.isNotEmpty;
    });
  }

  Widget _exibirMensagemProdutoInexistente() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade100,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(children: [
              Padding(
                padding: EdgeInsets.only(left: 6),
                child: Text("Floricultura Hassu"),
              )
            ]),
            GestureDetector(
              onTap: () {
                estadoApp.mostrarProdutos();
              },
              child: const Icon(Icons.arrow_back),
            )
          ],
        ),
      ),
      body: const SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: Colors.red,
            ),
            Text(
              "Oops! Parece que esse produto \n não existe! :/",
              style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w300,
                  fontSize: 20,
                  color: Colors.black87),
            ),
            Text("Que tal selecionar outro produto :)",
                style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w200,
                    fontSize: 16,
                    color: Colors.black87))
          ],
        ),
      ),
    );
  }

  Widget _exibirMensagemComentariosInexistentes() {
    return const Expanded(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline_rounded, size: 32, color: Colors.red),
        Text(
          "Não existem comentários aqui :/",
          style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black87),
        )
      ],
    ));
  }

  Widget _exibirComentarios() {
    return Expanded(
        child: FlatList(
      data: _comentarios,
      loading: _carregandoComentarios,
      buildItem: (item, index) {
        String dataFormatada = DateFormat('dd/MM/yyyy HH:mm')
            .format(DateTime.parse(item["datetime"]));
        bool usuarioLogadoComentou = estadoApp.usuario != null &&
            estadoApp.usuario!.email == item["usuario"]["email"];

        return Dismissible(
          key: Key(item["_id"].toString()),
          direction: usuarioLogadoComentou
              ? DismissDirection.endToStart
              : DismissDirection.none,
          background: Container(
              alignment: Alignment.centerRight,
              child: const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: Icon(Icons.delete, color: Colors.red))),
          child: Card(
              color: usuarioLogadoComentou ? Colors.green[100] : Colors.white,
              child: Column(children: [
                Padding(
                    padding: const EdgeInsets.all(6),
                    child: Container(
                        alignment: Alignment.topLeft,
                        child: Text(item["conteudo"],
                            style: const TextStyle(fontSize: 12)))),
                Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      children: [
                        Padding(
                            padding:
                                const EdgeInsets.only(right: 10.0, left: 6.0),
                            child: Text(
                              dataFormatada,
                              style: const TextStyle(fontSize: 12),
                            )),
                        Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: Text(
                              item["usuario"]["nome"],
                              style: const TextStyle(fontSize: 12),
                            )),
                      ],
                    )),
              ])),
          onDismissed: (direction) {
            if (direction == DismissDirection.endToStart) {
              final comentario = item;
              setState(() {
                _comentarios.removeAt(index);
              });

              showDialog(
                  context: context,
                  builder: (BuildContext contexto) {
                    return AlertDialog(
                      title: const Text("Deseja apagar o comentário?"),
                      actions: [
                        TextButton(
                            onPressed: () {
                              setState(() {
                                _comentarios.insert(index, comentario);
                              });

                              Navigator.of(contexto).pop();
                            },
                            child: const Text("NÃO")),
                        TextButton(
                            onPressed: () {
                              setState(() {});

                              Navigator.of(contexto).pop();
                            },
                            child: const Text("SIM"))
                      ],
                    );
                  });
            }
          },
        );
      },
    ));
  }

  void _adicionarComentarios() {
    String conteudo = _controladorNovoComentario.text.trim();
    if (conteudo.isNotEmpty) {
      final comentario = {
        "conteudo": conteudo,
        "usuario": {
          "nome": estadoApp.usuario!.nome,
          "email": estadoApp.usuario!.email,
        },
        "datetime": DateTime.now().toString(),
        "feed": estadoApp.idProduto
      };

      setState(() {
        _comentarios.insert(0, comentario);
      });

      _controladorNovoComentario.clear();
    } else {
      Toast.show("Digite algo...",
          duration: Toast.lengthLong, gravity: Toast.bottom);
    }
  }

  Widget _exibirProduto() {
    bool usuarioLogado = estadoApp.usuario != null;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.green.shade100,
        title: Row(children: [
          Row(
            children: [
              Image.asset("lib/recursos/imagens/avatar.png", width: 38),
              const Padding(
                padding: EdgeInsets.only(left: 80.0, bottom: 5.0),
                child: Text(
                  "Floricultura Hassu",
                  style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 17,
                      fontWeight: FontWeight.w300),
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              estadoApp.mostrarProdutos();
            },
            child: const Icon(Icons.arrow_back, size: 30),
          )
        ]),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 180,
            child: Stack(children: [
              PageView.builder(
                itemCount: 3,
                controller: _controladorSlides,
                onPageChanged: (slide) {
                  setState(() {
                    _slideSelecionado = slide;
                  });
                },
                itemBuilder: (context, pagePosition) {
                  return Image.asset('lib/recursos/imagens/planta-02.png',
                      fit: BoxFit.cover);
                },
              ),
              Align(
                  alignment: Alignment.topRight,
                  child: Column(children: [
                    usuarioLogado
                        ? IconButton(
                            onPressed: () {
                              if (_curtiu) {
                                setState(() {
                                  _produto['likes'] = _produto['likes'] - 1;

                                  _curtiu = false;
                                });
                              } else {
                                setState(() {
                                  _produto['likes'] = _produto['likes'] + 1;

                                  _curtiu = true;
                                });

                                Toast.show("Obrigado pela avaliação 💚",
                                    duration: Toast.lengthLong,
                                    gravity: Toast.bottom);
                              }
                            },
                            icon: Icon(_curtiu
                                ? Icons.favorite
                                : Icons.favorite_border),
                            color: Colors.red,
                            iconSize: 26)
                        : const SizedBox.shrink(),
                    IconButton(
                        onPressed: () {
                          final texto =
                              '${_produto["nome"]} por R\$ ${_produto["preco"].toString()} disponível na Floricultura Hassu.\n\n\nBaixe o App na PlayStore!';

                          FlutterShare.share(
                              title: "Floricultura Hassu", text: texto);
                        },
                        icon: const Icon(Icons.share),
                        color: Colors.white,
                        iconSize: 30)
                  ]))
            ]),
          ),
          SizedBox(
            height: 210,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.all(6.0),
                  child: Text(
                    _produto["nome"],
                    style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w400,
                        fontSize: 20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    _produto["descricao"],
                    style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w300,
                        fontSize: 16),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Text(
                        "R\$ ${_produto["preco"].toString()}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                            fontSize: 16),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6.0, top: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.favorite_rounded,
                        color: Colors.redAccent,
                        size: 30,
                      ),
                      Text(
                        _produto["likes"].toString(),
                        style: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w200,
                            fontSize: 16),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            height: 230,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: Text(
                    "Cuidados",
                    style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w400,
                        fontSize: 20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    _produto["cuidados"],
                    style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w300,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(
                  height: 25.0,
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Image.asset(
                        "lib/recursos/imagens/icone-01.png",
                        height: 24.0,
                      ),
                      Image.asset(
                        "lib/recursos/imagens/icone-02.png",
                        height: 24.0,
                      ),
                      Image.asset(
                        "lib/recursos/imagens/icone-03.png",
                        height: 24.0,
                      ),
                      Image.asset(
                        "lib/recursos/imagens/icone-04.png",
                        height: 24.0,
                      ),
                      Image.asset(
                        "lib/recursos/imagens/icone-05.png",
                        height: 24.0,
                      ),
                    ]),
              ],
            ),
          ),
          const Center(
            child: Text(
              "Comentarios",
              style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w400),
            ),
          ),
          usuarioLogado
              ? Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: TextField(
                      controller: _controladorNovoComentario,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                          enabledBorder: const OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.black87, width: 0.0),
                          ),
                          border: const OutlineInputBorder(),
                          hintStyle: const TextStyle(fontSize: 14),
                          hintText: 'Digite aqui seu comentário...',
                          suffixIcon: GestureDetector(
                              onTap: () {
                                _adicionarComentarios();
                              },
                              child: const Icon(Icons.send,
                                  color: Colors.black87)))))
              : const SizedBox.shrink(),
          _temComentarios
              ? _exibirComentarios()
              : _exibirMensagemComentariosInexistentes(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget detalhes = const SizedBox.shrink();

    if (_temProduto == _EstadoProduto.naoVerificado) {
      detalhes = const SizedBox.shrink();
    } else if (_temProduto == _EstadoProduto.temProduto) {
      detalhes = _exibirProduto();
    } else {
      detalhes = _exibirMensagemProdutoInexistente();
    }

    return detalhes;
  }
}
