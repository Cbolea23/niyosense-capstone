from rest_framework.renderers import JSONRenderer

class StandardResponseRenderer(JSONRenderer):
    def render(self, data, accepted_media_type=None, renderer_context=None):
        status_code = renderer_context['response'].status_code if renderer_context else 200
        
        success = status_code < 400
        message = "Success" if success else "Error processing request"
        errors = None

        if not success:
            errors = data
            data = None

        response_structure = {
            "success": success,
            "message": message,
            "data": data,
            "errors": errors,
            "statusCode": status_code
        }

        return super().render(response_structure, accepted_media_type, renderer_context)