using UnityEngine;

namespace HMK
{
    public static class RectTransformExtensions
    {
        public static void SetAnchoredPositionX(this RectTransform self, float x)
        {
            Vector2 p = self.anchoredPosition;
            p.x = x;
            self.anchoredPosition = p;
        }

        public static void SetAnchoredPositionY(this RectTransform self, float y)
        {
            Vector2 p = self.anchoredPosition;
            p.y = y;
            self.anchoredPosition = p;
        }

        public static void SetSizeDeltaWidth(this RectTransform @this, float width)
        {
            Vector2 size = @this.sizeDelta;
            size.x = width;
            @this.sizeDelta = size;
        }

        public static void SetSizeDeltaHeight(this RectTransform @this, float height)
        {
            Vector2 size = @this.sizeDelta;
            size.y = height;
            @this.sizeDelta = size;
        }
    }
}