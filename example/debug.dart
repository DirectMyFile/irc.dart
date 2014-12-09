import 'package:irc/client.dart';
import 'dart:io';
import 'dart:convert';

void main() {

  var config = new IrcConfig(host: "irc.directcode.org", port: 6667, nickname: "IRCDartBot", username: "DartBot", realname: "irc.dart debug bot");

  var bot = new CommandBot(config, prefix: "?");

  var configFile = new File("${Platform.environment["HOME"]}/.irc_debug.json");

  var conf = <String, String>{};

  if (configFile.existsSync()) {
    conf = JSON.decode(configFile.readAsStringSync());
  }
  
  bot.apply(BotBehaviors.joinOnInvite());
  bot.apply(BotBehaviors.rejoinOnKick());
  bot.apply(BotBehaviors.markAsBot());

  bot
      ..register((LineReceiveEvent event) {
        print(">> ${event.line}");
      })

      ..register((LineSentEvent event) {
        print("<< ${event.line}");
      })
      
      ..register((ReadyEvent event) {
        if (conf.containsKey("identityPassword")) bot.client.identify(username: conf["identityUsername"], password: conf["identityPassword"]);
        event.join("#directcode");
      })

      ..command("help", (CommandEvent event) {
        event.reply("> ${Color.BLUE}Commands${Color.RESET}: ${bot.commandNames().join(', ')}");
      })

      ..command("dart", (CommandEvent event) {
        event.reply("> Dart VM: ${Platform.version}");
      })

      ..command("ping", (CommandEvent event) {
        event.client.send("PING :cmd_${event.channel.name}");
      })

      ..register((PongEvent event) {
        if (event.message.startsWith("cmd_")) {
          event.client.sendMessage(event.message.replaceFirst("cmd_", ""), "> PONG!");
        }
      })

      ..command("opall", (CommandEvent event) {
        event.channel.allUsers.forEach((it) => event.channel.op(it));
      })

      ..command("nick", (CommandEvent event) {
        bot.client.changeNickname(event.args[0]);
      })

      ..command("join", (CommandEvent event) {
        if (event.checkArguments(1, "> Usage: join <channel>")) {
          bot.join(event.args[0]);
        }
      })

      ..command("topic", (CommandEvent event) {
        event.reply("> ${event.channel.topic}");
      })

      ..command("bans", (CommandEvent event) {
        event.reply("> ${event.channel.bans}");
      })

      ..command("raw", (CommandEvent event) {
        bot.client.send(event.args.join(" "));
      })
      
      ..command("spam", (CommandEvent event) {
        for (var i = 1; i <= 20; i++) {
          event.reply(i.toString());
        }
      })
      
      ..command("whois", (CommandEvent event) {
        if (event.args.length != 1) {
          event.reply("> Usage: whois <user>");
          return;
        }
        var user = event.args[0];
        event.client.whois(user).then((info) {
          event.reply("> ${info.username}");
        });
      })
      
      ..command("list-users", (CommandEvent event) {
        var reply = (msg) => bot.client.sendNotice(event.from, msg);
        reply("> Members: ${event.channel.members.join(", ")}");
        reply("> Ops: ${event.channel.ops.join(", ")}");
        reply("> Voices: ${event.channel.voices.join(", ")}");
        reply("> Owners: ${event.channel.owners.join(", ")}");
        reply("> Half-Ops: ${event.channel.halfops.join(", ")}");
      })

      ..command("part", (CommandEvent event) {
        if (event.checkArguments(1, "> Usage: part <channel>")) {
          bot.client.part(event.args[0]);
        }
      })

      ..command("quit", (CommandEvent event) {
        bot.disconnect().then((_) {
          exit(1);
        });
      })

      ..register((JoinEvent event) {
        print("<${event.channel.name}> ${event.user} has joined");
      })

      ..register((BotJoinEvent event) {
        print("Joined ${event.channel.name}");
      })

      ..register((BotPartEvent event) {
        print("Left ${event.channel.name}");
      })

      ..register((NickChangeEvent event) {
        print("${event.original} changed their nick to ${event.now}");
      })

      ..register((PartEvent event) {
        print("<${event.channel.name}> ${event.user} has left");
      })

      ..register((ErrorEvent event) {
        print("-------------------------------------------------------------------");
        switch (event.type) {
          case "socket":
            print(event.err);
            print(event.err.stackTrace);
            break;
          case "server":
            print("Server Error: ${event.message}");
            break;
          default:
            print("Error Type: ${event.type}");
            print("Message: ${event.message}");
            print("Error: ${event.err}");
            break;
        }
        print("-------------------------------------------------------------------");
        exit(1);
      })

      ..connect();
}
