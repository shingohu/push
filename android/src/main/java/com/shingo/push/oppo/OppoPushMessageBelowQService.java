package com.shingo.push.oppo;


import com.heytap.msp.push.service.CompatibleDataMessageCallbackService;

//兼容Q以下版本，继承CompatibleDataMessageCallbackService）
/**
 * 如果应用需要解析和处理Push消息（如透传消息），则继承PushService来处理，并在Manifest文件中申明Service
 * 如果不需要处理Push消息，则不需要继承PushService，直接在Manifest文件申明PushService即可
 */
public class OppoPushMessageBelowQService extends CompatibleDataMessageCallbackService {
}
