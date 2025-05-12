### 商品：苹果（水果）
```json
{
  "product_info": {
    "name": "苹果",
    "type": "水果",
    "price": 5.99,
    "stock": 100,
    "description": "新鲜红富士苹果"
  },
  "command": {
    "action": "add_to_cart",
    "params": {
      "product_id": "fruit_001",
      "quantity": 1  // 默认数量，可由用户对话修改
    },
    "confirm_message": "已为您加入购物车，是否立即结算？"
  }
}
```
### 商品：必胜客披萨套餐（外卖）
```json
{
  "product_info": {
    "name": "超级至尊披萨套餐",
    "type": "外卖套餐",
    "price": 128,
    "include": ["12寸披萨", "薯条拼盘", "2杯可乐"],
    "delivery_time": "40分钟"
  },
  "command": {
    "action": "order_combo",
    "params": {
      "combo_id": "combo_2201",
      "delivery_address": "用户最近收货地址",
      "remark": "不要辣椒"
    },
    "confirm_message": "预计40分钟送达，请确认地址：{{用户地址}}",
    "next_step": {
      "payment_type": ["在线支付", "货到付款"],
      "urgent_tip": "加急配送需+15元"
    }
  }
}
```
### 商品：健身蛋白粉（保健）
```json
{
  "product_info": {
    "name": "ON黄金标准蛋白粉",
    "type": "运动营养",
    "price": 589,
    "flavor": ["巧克力", "香草", "草莓"],
    "spec": "5磅/罐",
    "tag": ["买2送摇摇杯", "满999减100"]
  },
  "command": {
    "action": "add_with_promotion",
    "params": {
      "product_id": "supplement_889",
      "quantity": 2,
      "selected_flavor": "巧克力"
    },
    "confirm_message": "已选巧克力味x2，自动赠送摇摇杯",
    "promotion_popup": {
      "title": "凑单优惠",
      "tip": "再购411元商品可享满减"
    }
  }
}
```
### 商品：鲜花速递（礼品）
```json
{
  "product_info": {
    "name": "香槟玫瑰礼盒",
    "type": "同城速递",
    "price": 258,
    "contains": ["11支香槟玫瑰", "尤加利叶", "贺卡"],
    "delivery": ["即时配送", "指定日期送达"]
  },
  "command": {
    "action": "send_gift",
    "params": {
      "product_id": "flower_112",
      "delivery_time": "指定日期",
      "card_message": "祝您心情美丽！"
    },
    "confirm_message": "请选择配送日期并填写贺卡内容",
    "special_service": {
      "photo_confirmation": true,
      "anonymous_delivery": false
    }
  }
}
```
### 商品：小龙虾外卖（生鲜）
```json
{
  "product_info": {
    "name": "麻辣小龙虾3斤装",
    "type": "生鲜热食",
    "price": 168,
    "spicy_level": ["微辣", "中辣", "变态辣"],
    "package": ["含餐具", "无需餐具"]
  },
  "command": {
    "action": "order_hot_food",
    "params": {
      "product_id": "crawfish_003",
      "spicy": "中辣",
      "tableware": "含餐具",
      "note": "多放藕片配菜"
    },
    "confirm_message": "麻辣小龙虾（中辣）预计30分钟送达",
    "safety_notice": "生鲜食品不支持退货，请及时取餐"
  }
}
```