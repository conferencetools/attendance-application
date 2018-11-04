<?php
// Composer Autoloading isn't configured properly for this module :(
include_once __DIR__ . '/../vendor/zfr/zfr-stripe-module/Module.php';

return [
    'Zend\Mvc\Plugin\FlashMessenger',
    'Zend\Session',
    'Zend\Navigation',
    'Zend\Serializer',
    'Zend\Log',
    'AssetManager',
    'Zend\Router',
    'Zend\Validator',
    'Zend\Form',
    'TwbBundle',
    //'Zend\I18n',
    'DoctrineModule',
    'DoctrineORMModule',
    'Phactor\Zend',
    'Phactor\Doctrine\Zend',

    'ZfrStripeModule',
    'ConferenceTools\Attendance',
];
