import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ResourceLicensesView extends StatelessWidget {
  const ResourceLicensesView({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('笔顺与字体许可')),
    body: FutureBuilder<List<String>>(
      future: Future.wait(
        [
          'assets/licenses/ARPHICPL.TXT',
          'assets/licenses/LXGW-OFL.txt',
        ].map(rootBundle.loadString),
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('许可暂时无法打开，请返回重试。'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              '笔顺：Hanzi Writer Data / Make Me a Hanzi\n固定提交 68d10a4b21150cae5e1ebbd223eed289cf32d90c\n数据许可：Arphic Public License\n\n字帖字体：LXGW WenKai Regular v1.530\n字体许可：SIL Open Font License 1.1',
            ),
            const SizedBox(height: 24),
            for (final text in snapshot.data!)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SelectableText(
                  text,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        );
      },
    ),
  );
}
