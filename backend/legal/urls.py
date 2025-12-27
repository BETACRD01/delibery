from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import DocumentoLegalViewSet

router = DefaultRouter()
router.register(r'', DocumentoLegalViewSet, basename='documentos-legales')

urlpatterns = [
    path('', include(router.urls)),
]
