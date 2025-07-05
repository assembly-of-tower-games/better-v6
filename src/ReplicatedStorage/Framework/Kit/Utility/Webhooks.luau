type WebhookData = {
    Message: string,
    URL: string
}

local HttpService = game:GetService("HttpService")
local WebhooksUtil = {}

function WebhooksUtil:Post(Data: WebhookData): boolean
    local Message = Data.Message
    local URL = Data.URL

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