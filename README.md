# hxrpc

---

a [Haxe](https://haxe.org/) Library for interacting with the [Discord](https://discord.com/) API!
note that this library is windows exclusive as I don't have other os' to test on.

---


# Installation
---
```
haxelib install hxrpc
```
---

# Code Clearity

```haxe 
import hxrpc.DiscordRpc;
/** for reference, this is not how to actually use it. just what funcions do and what variables they hold  */
class Main {
	static function main():Void {
        /**
         * there's no need to create a 'new' instance
         * everything is handled on it's own
         */

        DiscordRpc.setup('appid', canLog (true/false));


        /**
         * the main function most people will be using
         */
        DiscordRpc.changePresence('status string', 'detail string', 'small icon key', 'small icon string', 'big icon key', 'big icon string', game end time);
    }
}
```
---
