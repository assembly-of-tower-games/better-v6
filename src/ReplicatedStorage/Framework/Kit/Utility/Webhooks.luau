type WebhookData = {
    Message: string,
    URL: string
}

local HttpService = game:GetService("HttpService")
local WebhooksUtil = {}

function WebhooksUtil:IsValidURL(URL: string): boolean
    local ProxyDomain = "https://webhook.lewisakura.moe"

    return string.sub(URL, 1, #ProxyDomain) ~= ProxyDomain
end

function WebhooksUtil:Post(Data: WebhookData): boolean
    local Message = Data.Message
    local URL = Data.URL

    if not WebhooksUtil:IsValidURL(URL) then 
        return false
    end

    local MessageData = {
        content = Message
    }
    MessageData = HttpService:JSONEncode(MessageData)

    local Success, Error = pcall(function()
        HttpService:PostAsync(URL, MessageData)
    end)

    if not Success then 
        warn("[Webhooks] "..Error)
        return false
    end

    return true
end

return WebhooksUtil