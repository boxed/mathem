import requests
import json

# https://www.mathem.se/Pages/products/AddToCart.aspx?AddProduct=true&ProductID=11371&noOfFooditem=1&_=1445106919270

found = set()

for page in range(1000):
    response = requests.get(f'https://api.mathem.io/product-search/noauth/search/query?q=&brands=&badges=&categories=&storeId=10&size=1000&index={page}&sortTerm=&sortOrder=&supplier=&searchToCart=false&memberType=undefined')
    assert response.status_code == 200
    products = json.loads(response.content)['products']
    if not products:
        break

    for product in products:
        name = product['name']
        price = product['price']
        product_id = product['id']
        if (name, price) in found:
            print('error', page, name, price)
            exit(1)
        found.add((name, price, product_id))

with open('products.json', 'w') as f:
    f.write(json.dumps([
        dict(name=name, price=price, id=id)
        for name, price, id in found
    ]))
