from __future__ import print_function
import json
import logging
import pprint
import sys

from . import six

from . import log as irods_log
from .exceptions import IrodsError, IrodsWarning

try:
    import jsonschema
except ImportError:
    pass

try:
    import requests
except ImportError:
    pass

def load_and_validate(config_file, schema_uri):
    l = logging.getLogger(__name__)
    try:
        # load configuration file
        config_dict = lib.open_and_load_json(config_file)
    except (OSError, ValueError) as e:
        six.reraise(IrodsError, IrodsError('\n\t'.join([
            'ERROR: Validation Failed for [{0}]:'.format(config_file),
            'against [{0}]'.format(schema_uri),
            '{0}: {1}'.format(e.__class__.__name__, e)])),
                          sys.exc_info()[2])
    validate_dict(config_dict, schema_uri, name=config_file)
    return config_dict

def validate_dict(config_dict, schema_uri, name=None):
    l = logging.getLogger(__name__)
    if name is None:
        name = schema_uri.rpartition('/')[2]
    try:
        e = jsonschema.exceptions
    except AttributeError:
        six.reraise(IrodsWarning, IrodsWarning(
                'WARNING: Validation failed for {0} -- jsonschema too old v[{1}]'.format(
                    name, jsonschema.__version__)),
            sys.exc_info()[2])
    except NameError:
        six.reraise(IrodsWarning, IrodsWarning(
                'WARNING: Validation failed for {0} -- jsonschema not installed'.format(
                    name)),
            sys.exc_info()[2])

    try:
        schema = get_initial_schema(schema_uri)
        l.debug('Validating %s against json schema:', name)
        l.debug(pprint.pformat(schema))
        jsonschema.validate(config_dict, schema)

    except (jsonschema.exceptions.RefResolutionError,   # could not resolve recursive schema $ref
            ValueError,                                 # 404s and bad JSON
            requests.exceptions.ConnectionError,        # network connection error
            requests.exceptions.Timeout                 # timeout
    ) as e:
        six.reraise(IrodsWarning, IrodsWarning('\n\t'.join([
                'WARNING: Validation Failed for [{0}]:'.format(name),
                'against [{0}]'.format(schema_uri),
                '{0}: {1}'.format(e.__class__.__name__, e)])),
                sys.exc_info()[2])
    except (jsonschema.exceptions.ValidationError,
            jsonschema.exceptions.SchemaError
    ) as e:
        six.reraise(IrodsError,  IrodsError('\n\t'.join([
                'ERROR: Validation Failed for [{0}]:'.format(name),
                'against [{0}]'.format(schema_uri),
                '{0}: {1}'.format(e.__class__.__name__, e)])),
                sys.exc_info()[2])

    l.info("Validating [%s]... Success", name)

def get_initial_schema(schema_uri):
    l = logging.getLogger(__name__)
    l.debug('Loading schema from %s', schema_uri)
    url_scheme = six.moves.urllib.parse.urlparse(schema_uri).scheme
    l.debug('Parsed URL: %s', schema_uri)
    scheme_dispatch = {
        'file': get_initial_schema_from_file,
        'http': get_initial_schema_from_web,
        'https': get_initial_schema_from_web,
    }

    try:
        return scheme_dispatch[url_scheme](schema_uri)
    except KeyError:
        raise IrodsError('ERROR: Invalid schema url: {}'.format(schema_uri))

def get_initial_schema_from_web(schema_uri):
    try:
        response = requests.get(schema_uri, timeout=5)
    except NameError:
        six.reraise(IrodsError, IrodsError(
            'WARNING: Validation failed for {0} -- requests not installed'.format(
                name)),
                          sys.exc_info()[2])

    # check response values
    try:
        # modern requests
        schema = json.loads(response.text)
    except AttributeError:
        # requests pre-v1.0.0
        response.encoding = 'utf8'
        schema = json.loads(response.content)
    return schema

def get_initial_schema_from_file(schema_uri):
    with open(schema_uri[7:], 'rt') as f:
        schema = json.load(f)
    return schema

logging.getLogger('requests.packages.urllib3.connectionpool').addFilter(irods_log.DeferInfoToDebugFilter())
logging.getLogger('urllib3.connectionpool').addFilter(irods_log.DeferInfoToDebugFilter())