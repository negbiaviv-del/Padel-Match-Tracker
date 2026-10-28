# יוצר קבצים בעלי שמות ייחודיים לפי תוכנם.
FROM alpine:3.20 AS assets

# מגדיר תיקיית עבודה זמנית לתהליך הבנייה.
WORKDIR /build

# מעתיק את קובצי הממשק לצורך יצירת הגרסה המוגשת.
COPY index.html styles.css app.js ./

# יוצר מזהה תוכן ומעדכן את עמוד הכניסה לשמות החדשים.
RUN asset_hash="$(sha256sum app.js styles.css | sha256sum | cut -c1-16)" \
    && mkdir /output \
    && sed "s/__BUILD_HASH__/${asset_hash}/g" index.html > /output/index.html \
    && cp styles.css "/output/styles.${asset_hash}.css" \
    && cp app.js "/output/app.${asset_hash}.js"

# מפעיל שרת קבצים ללא הרשאות מנהל.
FROM nginxinc/nginx-unprivileged:alpine

# מעתיק את הקבצים המוכנים אל התיקייה שמוגשת לדפדפן.
COPY --from=assets /output/ /usr/share/nginx/html/

# מחליף את הגדרת ברירת המחדל בהגדרת הפרויקט.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# מתעד את הפורט שעליו המכולה מאזינה.
EXPOSE 8080
