class FormatterService
  def self.format_user(user)
    return {
      "id": user.id,
      "username": user.username,
      "created_at": user.created_at,
      "last_active_at": user.last_active_at
    }
  end

  def self.format_user_token(user, token)
    return {
      "user": {
        "id": user.id,
        "username": user.username,
        "created_at": user.created_at,
        "last_active_at": user.last_active_at
      },
      "token": token
    }
  end

  def self.format_message(msg)
    return {
      "id": msg.id.to_s,
      "conversationId": msg.conversation_id.to_s,
      "senderId": msg.sender_id.to_s,
      "senderUsername": msg.sender.username,
      "senderRole": msg.sender_role,
      "content": msg.content,
      "timestamp": msg.created_at,
      "isRead": msg.is_read
    }
  end

  def self.format_conversation(conv, user)
    return {
      "id": conv.id.to_s,
      "title": conv.title,
      "status": conv.status,
      "questionerId": conv.initiator.id.to_s,
      "questionerUsername": conv.initiator.username,
      "assignedExpertId": conv.assigned_expert&.id&.to_s,
      "assignedExpertUsername": conv.assigned_expert&.username,
      "createdAt": conv.created_at,
      "updatedAt": conv.updated_at,
      "lastMessageAt": conv.last_message_at,
      "unreadCount": conv.unread_count(user)
    }
  end

  def self.format_profile(ep)
    return {
      "id": ep.id.to_s,
      "userId": ep.user_id.to_s,
      "bio": ep.bio || "",
      "knowledgeBaseLinks": ep.knowledge_base_links || [],
      "createdAt": ep.created_at,
      "updatedAt": ep.updated_at
    }
  end

  def self.format_assignment(ea)
    return {
      "id": ea.id.to_s,
      "conversationId": ea.conversation_id.to_s,
      "expertId": ea.user_id.to_s,
      "status": ea.conversation.status,
      "assignedAt": ea.assigned_at,
      "resolvedAt": ea.resolved_at,
      "rating": ea.rating
    }
  end
end
