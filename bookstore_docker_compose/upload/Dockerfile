FROM python:alpine
copy . /
RUN pip install -r requirements.txt
EXPOSE 80
CMD python ./bookstore-api.py