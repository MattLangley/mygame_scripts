defmodule PGS.PortalHandler do

    def handle(:game, "triggerAction", data) do
        # fire off the action in 1 second.  Note if you need such a fine grain
        # timer you should really be using "Sys.Time.callAfter" but for the
        # purposes of this example it should be fine.
        Sys.Game.scheduleAction(1000, "testAction", data)
        :ok
    end
    
    def handle(:game, "triggerEvent", data) do
        # fire off the action in 1 second.  Note if you need such a fine grain
        # timer you should really be using "Sys.Time.callAfter" but for the
        # purposes of this example it should be fine.
        {_, _taskId} = Sys.Game.scheduleEvent(1000, 2000, 5000, 2, "testEvent", data)
        :ok
    end

    def handle(:game, "announcement", data) do
        Sys.Game.publishAnnouncement(data["message"])
        Sys.Game.setOfflineMessage(data["message"])
        :ok
    end

    def handle(:game, "mailsend", data) do
        res = Sys.Mailbox.send(String.to_integer(data["pKey"]), -1, "Test Message", "Ready Player One!", Sys.Data.encode(:msgpack, %{"test" => "value"}), ["cmd"], -1)
        Sys.Log.info("Output = #{inspect res}")
        :ok
    end

    def handle(:player, "mailprocess", _data) do
        case Sys.Player.mailItems() do
            :failed -> Sys.Log.error("[PGS.Portal.Handler] mailprocess: Failed to pull mailbox items")
            []      -> Sys.Log.debug("[PGS.Portal.Handler] mailprocess: No items to process")
            mails   ->  for mail <- mails do
                            Sys.Player.mailExecute(Map.get(mail, :mailKey, Map.get(mail, "mailKey")), %{:cmd => "myArgs"})
                        end 
        end
        :ok
    end
    
    def handle(:player, "set_name", data) do
        Sys.Player.setName(data["name"])
    end

    def handle(:player, "modify_ore", data) do
        delta = String.to_integer(data["arg0"])
        ore = Sys.Player.sharedProperty("ore") + delta
        Sys.Player.setSharedProperty("ore", ore)
        %{"ore" => ore}
    end
    
    def handle(:player, "send_mail", data) do
        Sys.Player.mailSend(Sys.Player.pKey, data["subject"], data["message"])
    end

    def handle(:player, "send_mail_reward", data) do
        ore = String.to_integer(data["ore"])
        mailData = %{"type" => "gift", "args" => %{"ore" => ore}}
        Sys.Player.mailSend(Sys.Player.pKey, data["subject"], data["message"], mailData, ["cmd"])
    end

    def handle(:player, "credit_gems", data) do
        amt = Map.get(data, "amt", "1") |> String.to_integer
        Sys.Player.walletCredit(amt, "debug_portal")
    end

    def handle(:player, "debit_gems", data) do
        amt = Map.get(data, "amt", "1") |> String.to_integer
        Sys.Player.walletDebit(amt, "debug_portal")
    end

    def handle(:player, "ban_player", data) do
        Sys.Log.debug("[#{__MODULE__}.ban_player] data: #{inspect data}")
        Sys.Player.setStatus("banned", "Banned by portal")
    end

    def handle(:player, "block_player", data) do
        Sys.Log.debug("[#{__MODULE__}.block_player] data: #{inspect data}")
        Sys.Player.setStatus("blocked", "Blocked by portal")
    end

    def handle(:player, "change_player_status", data) do
        oldStatus = Sys.Player.status()
        status = data["status"]
        Sys.Log.debug("[#{__MODULE__}.change_player_status] #{oldStatus} -> #{status}")
        Sys.Player.setStatus(status, "Status changed by portal")
    end

    def handle(_type, _request, _data) do
        %{"status" => :failed, "reason" => "unknown portal request"}
    end

end
