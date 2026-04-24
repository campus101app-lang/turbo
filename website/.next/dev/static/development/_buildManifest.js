self.__BUILD_MANIFEST = {
  "__rewrites": {
    "afterFiles": [],
    "beforeFiles": [
      {
        "has": [
          {
            "type": "header",
            "key": "next-url",
            "value": "/.*"
          }
        ],
        "source": "/join-waitlist",
        "destination": "/(.)join-waitlist"
      },
      {
        "has": [
          {
            "type": "header",
            "key": "next-url",
            "value": "/.*"
          }
        ],
        "source": "/join-waitlist",
        "destination": "/(.)join-waitlist"
      },
      {
        "has": [
          {
            "type": "header",
            "key": "next-url",
            "value": "/.*"
          }
        ],
        "source": "/join-waitlist",
        "destination": "/(.)join-waitlist"
      }
    ],
    "fallback": []
  },
  "sortedPages": [
    "/_app",
    "/_error"
  ]
};self.__BUILD_MANIFEST_CB && self.__BUILD_MANIFEST_CB()