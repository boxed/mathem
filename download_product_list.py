# coding=utf-8
from bs4 import BeautifulSoup
from pickle import dump
import requests

# https://www.mathem.se/Pages/products/AddToCart.aspx?AddProduct=true&ProductID=11371&noOfFooditem=1&_=1445106919270

products = set()

for page in xrange(1000):
    print page
    response = requests.get('https://www.mathem.se/ProductListing/LoadProductList?categoryId=0&supplierId=0&onlyDeliProducts=False&sectionName=Populäraste%20varorna&q=&pageIndex={}&q=&_=1445106919269'.format(page+1))
    assert response.status_code == 200
    soup = BeautifulSoup(response.text, 'html.parser')

    page_products = soup.find_all(attrs={'class': 'prod-info'})
    if not len(page_products):
        break

    for product in page_products:
        name = product.find(attrs={'class': 'prodHeader'}).text.strip()
        price = product['data-price']
        product_id = product['data-product-div-id']
        if (name, price) in products:
            print 'error', page, name, price
            exit()
        products.add((name, price, product_id))

dump(products, open('products.pickle', 'w'))
