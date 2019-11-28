<?php

$modules = [
    'BsbFlysystem',
    'Zend\Mail',
    'Zend\Mvc\Plugin\FlashMessenger',
    'Zend\Session',
    'Zend\Navigation',
    'Zend\Serializer',
    'Zend\Log',
    'Zend\Router',
    'Zend\Validator',
    'Zend\Form',
    'TwbBundle',
    //'Zend\I18n',
    'DoctrineModule',
    'DoctrineORMModule',
    'Carnage\ZendfonyCli',
    'Phactor\Zend',
    'Phactor\Doctrine\Zend',
    'ConferenceTools\Admin',
    'ConferenceTools\Authentication',
];

$speakerModule = filter_var(getenv('ENABLE_SPEAKER_MODULE'), FILTER_VALIDATE_BOOLEAN, ['options' => ['default' => false]]);
$attendanceModule = filter_var(getenv('ENABLE_ATTENDANCE_MODULE'), FILTER_VALIDATE_BOOLEAN, ['options' => ['default' => false]]);
$stripeModule = filter_var(getenv('ENABLE_STRIPE_MODULE'), FILTER_VALIDATE_BOOLEAN, ['options' => ['default' => $attendanceModule]]);

if ($attendanceModule) {
    $modules[] = 'ConferenceTools\Attendance';
}

if ($stripeModule) {
    $modules[] = 'ConferenceTools\StripePaymentProvider';
}

if ($speakerModule) {
    $modules[] = 'ConferenceTools\Speakers';
}

return $modules;