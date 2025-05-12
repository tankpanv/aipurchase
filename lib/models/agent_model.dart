class Agent {
  final String id;
  final String name;
  final String description;
  final String prompt;
  final String iconId;
  final List<String> tags;

  Agent({
    required this.id,
    required this.name,
    required this.description,
    required this.prompt,
    required this.iconId,
    this.tags = const [],
  });

  static List<Agent> getAgents() {
    return [
      Agent(
        id: 'food_safety',
        name: '食品安全问答',
        description: '解答食品安全问题，提供相关知识和建议',
        prompt: '你是一个食品安全专家，精通食品安全法规、食品添加剂、食品卫生等方面的知识。请根据用户的问题，提供准确、专业的食品安全建议。',
        iconId: 'restaurant',
        tags: ['食品', '安全', '健康'],
      ),
      Agent(
        id: 'travel',
        name: '出行助手',
        description: '提供旅行路线规划、交通工具推荐等服务',
        prompt: '你是一个出行助手，擅长规划旅行路线、推荐交通工具、提供景点信息等。请根据用户需求提供实用的出行建议和路线规划服务。',
        iconId: 'map',
        tags: ['旅行', '交通', '地图'],
      ),
      Agent(
        id: 'shopping',
        name: '购物推荐',
        description: '基于用户需求推荐合适的商品',
        prompt: '你是一个专业的购物顾问，擅长根据用户需求推荐合适的商品。请详细了解用户的需求、预算和偏好，然后提供有针对性的商品推荐，包括价格、特点、优势等信息。',
        iconId: 'shopping_cart',
        tags: ['购物', '推荐', '比价'],
      ),
      Agent(
        id: 'customer_service',
        name: '智能客服',
        description: '解答产品使用问题，处理售后服务',
        prompt: '你是一个专业的客服代表，擅长解答产品使用问题，处理售后服务请求。请根据用户描述的问题，提供清晰、耐心的解答，并尽可能提供解决方案。如需人工服务，请告知用户联系方式。',
        iconId: 'headset_mic',
        tags: ['客服', '售后', '帮助'],
      ),
    ];
  }

  static Agent? getAgentById(String id) {
    try {
      return getAgents().firstWhere((agent) => agent.id == id);
    } catch (e) {
      return null;
    }
  }
} 