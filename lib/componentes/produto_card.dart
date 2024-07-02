import 'package:floricultura/estado.dart';
import 'package:flutter/material.dart';

class ProdutoCard extends StatelessWidget {
  final dynamic produto;

  const ProdutoCard({super.key, required this.produto});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        estadoApp.mostrarDetalhes(produto["_id"]);
      },
      child: Card(
        child: Column(
          children: [
            Image.asset("lib/recursos/imagens/planta-02.png"),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                produto["nome"],
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Montserrat',
                    fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 5, bottom: 20),
              child: Text(
                produto["descricao"],
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10, bottom: 5),
                  child: Text("R\$ ${produto['preco'].toString()}"),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
