import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { SignaturePlugin } from './plugins/signature-plugin/src/simple-plugin';

export default {
  system: appTasks, /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins: [
    {
      pluginId: 'signature-plugin',
      apply: (target: any) => {
        const plugin = new SignaturePlugin({
          autoDetect: true,
          autoGenerate: true,
          signaturePath: './.signature',
          verbose: true
        });
        plugin.apply(target);
      }
    }
  ]
}